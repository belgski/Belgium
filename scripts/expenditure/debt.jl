let
    df = datasets["debt"]
    df_debt = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select {REF_AREA = i.REF_AREA.name, i.OBS_VALUE}
        @collect DataFrame
    end


    sp = sortperm(df_debt.OBS_VALUE)
    ref_areas = df_debt.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, df_debt.OBS_VALUE[sp], legend=false, yaxis="Debt/GDP",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"debt_per_gdp.png"))


    df = datasets["government_spending_by_function"]
    df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select i
        @collect DataFrame
    end
    df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"])

    df = @from i in df begin
        @join j in df on i.REF_AREA equals j.REF_AREA
        @where i.EXPENDITURE.name == "Total"
        @where j.EXPENDITURE.name == "Public debt transactions"
        @select {REF_AREA = i.REF_AREA.name,TOTAL=i.OBS_VALUE, DEBT = j.OBS_VALUE}
        @collect DataFrame
    end

    ratios = df.DEBT ./ df.TOTAL .*100

    sp = sortperm(ratios)
    ref_areas = df.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, yaxis="Debt spending/Total %",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"debt_spending.png"))
end