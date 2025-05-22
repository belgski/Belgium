let
    df = datasets["wage_taxation"]
    takehome_pay = @from i in df begin
        @where i.TIME_PERIOD == TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.MEASURE.name == "Net income after taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @where i.INCOME_SPOUSE.name == "100% of average wage"

        @where i.UNIT_MEASURE.name =="National currency"
        @where i.HOUSEHOLD_TYPE.name == "Couple, 2 children"
        @select {REF_AREA = i.REF_AREA.name ,i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])
    net_household_income = takehome_pay.OBS_VALUE[1]

    df_housing_cost = datasets["BE_housing_cost_by_muncipality"]
    df_housing_cost = @from i in df_housing_cost begin
        @where i.CD_YEAR == TIME_PERIOD
        @where i.CD_PERIOD == "Y"
        @where i.CD_niveau_refnis == 5
        @select i
        @collect DataFrame
    end

    # given the net_household_income we can calculate the amount of money that can sensibly be given to a bank; capped at 1/3
    # we will take out a 25 year loan

    yearly_rent = 3
    monthly_rent = yearly_rent/12 / 100
    num_months = 20*12
    house_budget = (net_household_income/(3*12)) * (1-(1+monthly_rent)^(-num_months))/monthly_rent
    
    open(joinpath(FIGURE_DIR,"housing_budget_text.txt"),"w") do f
        write(f,"The median household of a couple with two children has a yearly net income of $(sprintf1("%0.1f",net_household_income)) Euro. 
        There is a rough rule of thumb that you should spend at most one third of your income on housing. 
        If we assume an interest rate of 3% and we take out of a loan for 20 years, then the maximum reasonable budget is $(sprintf1("%0.1f",house_budget)) Euro.")
    end

    for (housetype,descr) in (("closed","Huizen met 2 of 3 gevels (gesloten + halfopen bebouwing)"),("open","Huizen met 4 of meer gevels (open bebouwing)"))
        sub_df_housing_cost = @from i in df_housing_cost begin
            @where i.CD_TYPE_NL == descr
            @select i
            @collect DataFrame
        end



        (outline,postal,postal_name) = datasets["BE_shapefiles"]
        colorscheme = cgrad([:lightgreen,:yellow,:orange,:red,:purple]);

        table = Shapefile.Table(outline);
        belgium_outline = first(Shapefile.shapes(table));
        belgium_crs = ArchGDAL.importEPSG(4326);
        pl = plot(belgium_outline,color=:gray,xaxis=false,yaxis=false,grid=false,title = descr,titlefontsize=9);

        table = Shapefile.Table(postal);
        postcode_crs = ArchGDAL.importEPSG(31370);


        for row in table
            pcode = parse(Int,row.nouveau_PO);

            shit = findfirst(==(pcode),postal_name.postal)
            isnothing(shit) && continue

            hit1 = findfirst(==(postal_name.name[shit]),sub_df_housing_cost.CD_REFNIS_NL)
            hit2 = findfirst(==(postal_name.name[shit]),sub_df_housing_cost.CD_REFNIS_FR)

            hit = isnothing(hit1) ? hit2 : hit1
            isnothing(hit) && continue

            
            median_cost = sub_df_housing_cost.MS_P_50_median[hit]/house_budget
            ismissing(median_cost) && continue

            shp = Shapefile.shape(row).points;
            shp_x = map(x->x.x,shp);
            shp_y = map(x->x.y,shp);
            shp_z = map(x->0.0,shp);

            ArchGDAL.createcoordtrans(postcode_crs,belgium_crs) do transform
                ArchGDAL.transform!(shp_x,shp_y,shp_z,transform);
            end

            col = median_cost > 1 ? :black : colorscheme[median_cost];


            plot!(pl,ArchGDAL.createpolygon(shp_y,shp_x),legend=false,color=col,linecolor=col)
        end

        botleft_cgrad = (2.5,49.7)
        wh_cgrad = (0.3,0.7)

        rect(p,wh) = Shape([p[1],p[1]+wh[1],p[1]+wh[1],p[1]],[p[2],p[2],p[2]+wh[2],p[2]+wh[2]])
        plot!(pl,rect(botleft_cgrad,wh_cgrad),linecolor=:black,linewidth=2)
        c_scale_interval = 0.01
        for c_scale in 0:c_scale_interval:1
            botleft_now = (botleft_cgrad[1],botleft_cgrad[2]+wh_cgrad[2]*c_scale)
            plot!(pl,rect(botleft_now,(wh_cgrad[1],wh_cgrad[2]*c_scale_interval)),color = colorscheme[c_scale],linecolor = colorscheme[c_scale])
        end

        annotate!(botleft_cgrad[1]+wh_cgrad[1], botleft_cgrad[2], Plots.text(" 0 %", 9, :left, :black))
        #annotate!(botleft_cgrad[1]+wh_cgrad[1], botleft_cgrad[2]+wh_cgrad[2]/2, Plots.text("- 50 %", 9, :left, :black))
        annotate!(botleft_cgrad[1]+wh_cgrad[1], botleft_cgrad[2]+wh_cgrad[2], Plots.text(" 100 %", 9, halign = :left, :black))
        savefig(joinpath(FIGURE_DIR,"housing_affordability_by_muncipality_$(housetype).png"))
    end
end