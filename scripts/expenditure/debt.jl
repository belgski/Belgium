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
    bar(ref_areas, df_debt.OBS_VALUE[sp], legend=false, title="Debt/GDP" * get_source("debt"), yaxis="Debt/GDP",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm,titlefont=font(10,"Computer Modern"))
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
    bar(ref_areas, ratios[sp], legend=false, title="Debt spending/Total %" * get_source("government_spending_by_function"), yaxis="Debt spending/Total %",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm,titlefont=font(10,"Computer Modern"))
    savefig(joinpath(FIGURE_DIR,"debt_spending.png"))

    df = datasets["government_spending_by_function"]
    df = @from i in df begin
        @where i.REF_AREA.name == TARGET_NAME
        @select i
        @collect DataFrame
    end
    df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"])
    df = @from i in df begin
        @join j in df on i.REF_AREA equals j.REF_AREA
        @where i.TIME_PERIOD == j.TIME_PERIOD
        @where i.EXPENDITURE.name == "Total"
        @where j.EXPENDITURE.name == "Public debt transactions"
        @select {REF_AREA = i.REF_AREA.name,RATIO=j.OBS_VALUE/i.OBS_VALUE , TIME_PERIOD=i.TIME_PERIOD}
        @collect DataFrame
    end
    sp = sortperm(Int.(df.TIME_PERIOD))
    plot(
        Int.(df.TIME_PERIOD[sp]),
        df.RATIO[sp].*100,
        legend=false,
        title="Debt spending over time" * get_source("government_spending_by_function"),
        yaxis="Debt spending/Total %",
        xaxis="Year",
        bottommargin=5mm,
        marker=:circle,
        markersize=5
        ,titlefont=font(10,"Computer Modern")
    )
    savefig(joinpath(FIGURE_DIR,"debt_spending_time.png"))

    df = datasets["long_term_yield"]
    df = @from i in df begin
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.TIME_PERIOD == TIME_PERIOD
        @select {REF_AREA = i.REF_AREA.name,OBS_VALUE=i.OBS_VALUE}
        @collect DataFrame
    end
    ratios = df.OBS_VALUE
    
    sp = sortperm(ratios)
    ref_areas = df.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, title="Long term yield" * get_source("long_term_yield"), yaxis="Long term yield",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm,titlefont=font(10,"Computer Modern"))
    savefig(joinpath(FIGURE_DIR,"long_term_yield.png"))
    
end