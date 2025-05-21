let
    df = datasets["infra_annual_labour"]
    df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select i
        @collect DataFrame
    end
    df.OBS_VALUE .*= [10.0^x for x in df.UNIT_MULT]


    unempl_rate_df = @from i in df begin
        @where i.MEASURE.name == "Unemployment rate"
        @select {REF_AREA = i.REF_AREA.name,UNEMPL_RATE = i.OBS_VALUE}
        @collect DataFrame
    end


    sp = sortperm(unempl_rate_df.UNEMPL_RATE)
    ref_areas = unempl_rate_df.REF_AREA[sp]
    ref_area_labels = ref_areas
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_area_labels, unempl_rate_df.UNEMPL_RATE[sp], legend=false, yaxis="Unemployment rate",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"unemployment_rate.png"))


    unempl_pop_df = @from i in df begin
        @where i.MEASURE.name == "Unemployment"
        @select {REF_AREA = i.REF_AREA.name,UNEMPL_POP = i.OBS_VALUE}
        @collect DataFrame
    end



    df = datasets["government_spending_by_function"]
    budget = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.EXPENDITURE.name == "Unemployment"
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


    joined = @from i in budget begin
        @join j in unempl_pop_df on i.REF_AREA equals j.REF_AREA
        @join k in takehome_pay on i.REF_AREA equals k.REF_AREA

        @select {i.REF_AREA, BUDGET = i.OBS_VALUE, NUM_UNEMPL = j.UNEMPL_POP , PAY = k.OBS_VALUE}
        @collect DataFrame
    end

    ratios = joined.BUDGET ./ (joined.NUM_UNEMPL .* joined.PAY)

    sp = sortperm(ratios)
    ref_areas = joined.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, yaxis="Ratio",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)

    savefig(joinpath(FIGURE_DIR,"unemployment_budget_ratio.png"))
end