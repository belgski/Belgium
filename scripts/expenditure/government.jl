let
    df = datasets["government_spending_by_function"]
    gov_spending_df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.EXPENDITURE.name == "Executive and legislative organs, financial and fiscal affairs, external affairs"
        @select {REF_AREA = i.REF_AREA.name,i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    gov_spending_df[!,"OBS_VALUE"] .*=10 .^(gov_spending_df[!,"UNIT_MULT"])

    df = datasets["wage_taxation"]
    takehome_pay = @from i in df begin
        @where i.TIME_PERIOD == TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.MEASURE.name == "Net income after taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @where i.UNIT_MEASURE.name =="National currency"
        @where i.HOUSEHOLD_TYPE.name == "Single person, no children"
        @select {REF_AREA = i.REF_AREA.name ,i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])


    df = datasets["population"]
    total_pop = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.AGE.name == "Total"
        @select {REF_AREA = i.REF_AREA.name, i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    total_pop[!,"OBS_VALUE"] .*=10 .^(total_pop[!,"UNIT_MULT"])

    joined = @from i in gov_spending_df begin
        @join j in total_pop on i.REF_AREA equals j.REF_AREA
        @join k in takehome_pay on i.REF_AREA equals k.REF_AREA

        @select {i.REF_AREA, BUDGET = i.OBS_VALUE, NUM_POP = j.OBS_VALUE , PAY = k.OBS_VALUE}
        @collect DataFrame
    end


    ratios = joined.BUDGET ./ (joined.NUM_POP .* joined.PAY)

    sp = sortperm(ratios)
    ref_areas = joined.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, yaxis="Ratio",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)

    savefig(joinpath(FIGURE_DIR,"gov_budget.png"))


    df = DataFrame("X" => (joined.NUM_POP .* joined.PAY), "Y" => joined.BUDGET)
    ols = lm(@formula(Y ~ X), df)
    open(joinpath(FIGURE_DIR,"government_r2.txt"),"w") do f
        write(f,sprintf1("%.3g",r2(ols))*".")
    end



    belgium_pos = findfirst(==(TARGET_NAME),ref_areas)
    better_ind = Int(floor(length(ratios)/3))
    better_pos = ref_areas[better_ind]

    projected_savings =  joined.BUDGET[sp][belgium_pos] - ratios[sp][better_ind]*(joined.NUM_POP .* joined.PAY)[sp][belgium_pos]

    open(joinpath(FIGURE_DIR,"government_saving.txt"),"w") do f
        write(f,"If we following the example of $(better_pos), we would save approximately $(sprintf1("%0.1f",projected_savings/10^9)) Billion Euro.")
    end

    df = datasets["government_spending_by_function"]
    gov_spending_df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name == TARGET_NAME
        @where i.EXPENDITURE.name == "Total"
        @select {i.OBS_VALUE,i.UNIT_MULT,i.UNIT_MEASURE}
        @collect DataFrame
    end
    gov_spending_df[!,"OBS_VALUE"] .*=10.0 .^(gov_spending_df[!,"UNIT_MULT"].-9)
    
    df_totalrev = datasets["total_government_revenue"]
    df_totalrev = @from i in df_totalrev begin
        @where i.unit == "MIO_EUR"
        @where i.sector == "S13"
        @where i.na_item == "TR"
        @where get(EUROPEAN_AREA_ISO_NAME,i.geo,"") == TARGET_NAME
        @select {OBS_VALUE = getproperty(i,Symbol("$TIME_PERIOD"))}
        @collect DataFrame
    end

    df_totalrev[!,"OBS_VALUE"] .*=10.0 .^(-3)

    bar(["Projected savings","Deficit"], [projected_savings/10^9,gov_spending_df.OBS_VALUE[1]-df_totalrev.OBS_VALUE[1]],legend = false,yaxis = "Billion Euro")
    savefig(joinpath(FIGURE_DIR,"government_savings.png"))
end