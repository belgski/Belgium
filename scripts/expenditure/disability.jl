let
    df_disability_rate = datasets["disability_rate"]

    df_disability_rate = @from i in df_disability_rate begin
        @where i.sex == "T"
        @where i.age == "Y_GE16"
        @where i.lev_limit == "SM_SEV"
        @where i.unit == "PC"
        @where i.citizen == "NAT"
        @where i.geo in EUROPEAN_AREA_ISOS
        @select i
        @collect DataFrame
    end

    ratios = df_disability_rate[!,"$TIME_PERIOD"]
    sp = sortperm(ratios)
    ref_areas = df_disability_rate.geo[sp]
    ref_area_labels = [EUROPEAN_AREA_ISO_NAME[c] for c in ref_areas]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_area_labels]
    bar(ref_area_labels, ratios[sp], legend=false, yaxis="Disability rate",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"disability_rate.png"))


    df = datasets["infra_annual_labour"]
    df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select i
        @collect DataFrame
    end
    df.OBS_VALUE .*= [10.0^x for x in df.UNIT_MULT]


    unempl_rate_df = @from i in df begin
        @where i.MEASURE.name == "Inactivity rate"
        @select {REF_AREA = i.REF_AREA.name,UNEMPL_RATE = i.OBS_VALUE}
        @collect DataFrame
    end

    histogram(unempl_rate_df.UNEMPL_RATE,xaxis="Inactivity rate",yaxis="number of countries",legend=false)
    vline!(unempl_rate_df.UNEMPL_RATE[unempl_rate_df.REF_AREA .== TARGET_NAME])
    savefig(joinpath(FIGURE_DIR,"inactivity_rate.png"))


    unempl_pop_df = @from i in df begin
        @where i.MEASURE.name == "Persons outside the labour force"# == unempl_pop_code
        @select {REF_AREA = i.REF_AREA.name,UNEMPL_POP = i.OBS_VALUE}
        @collect DataFrame
    end



    df = datasets["government_spending_by_function"]
    budget = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.EXPENDITURE.name == "Sickness and disability"
        @select {REF_AREA = i.REF_AREA.name,i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    budget[!,"OBS_VALUE"] .*=10 .^(budget[!,"UNIT_MULT"])


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
        @select {REF_AREA = i.REF_AREA.name ,i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    total_pop[!,"OBS_VALUE"] .*=10 .^(total_pop[!,"UNIT_MULT"])


    joined = @from i in budget begin
        @join j in unempl_pop_df on i.REF_AREA equals j.REF_AREA
        @join k in takehome_pay on i.REF_AREA equals k.REF_AREA
        @join l in total_pop on i.REF_AREA equals l.REF_AREA

        @select {i.REF_AREA, BUDGET = i.OBS_VALUE, NUM_UNEMPL = j.UNEMPL_POP , PAY = k.OBS_VALUE, POP = l.OBS_VALUE}
        @collect DataFrame
    end

    df = DataFrame("Y" => joined.BUDGET, "X1" => joined.NUM_UNEMPL .* joined.PAY , "X2" => joined.POP .* joined.PAY)
    ols = lm(@formula(Y ~ X1 + X2), df)
    open(joinpath(FIGURE_DIR,"disability_r2.txt"),"w") do f
        write(f,sprintf1("%.3g",r2(ols))*".")
    end
    ratios = joined.BUDGET ./ predict(ols,df)
    sp = sortperm(ratios)
    ref_areas = joined.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"sick_disabled_budget_ratio.png"))
end