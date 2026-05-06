let
    df = datasets["income_distribution_quantiles"]

    belgian_distribution = @from i in df begin
        @where i.geo == "BE"
        @where i.freq == "A"
        @where startswith(i.quantile,"D")
        @where i.currency == "EUR"
        @where i.indic_il == "SHARE"
        @select {i.quantile, OBS_VALUE = Float64(getfield(i,Symbol(TIME_PERIOD)))}
        @collect DataFrame
    end
    sp = sortperm([parse(Int,i[2:end]) for i in belgian_distribution.quantile])
    bar(belgian_distribution.quantile[sp],belgian_distribution.OBS_VALUE[sp],alpha=0.3, label = "Belgium", title="Decile wage distribution" * get_source("income_distribution_quantiles"),titlefont=font(10,"Computer Modern"))


    belgian_distribution = @from i in df begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.freq == "A"
        @where startswith(i.quantile,"D")
        @where i.currency == "EUR"
        @where i.indic_il == "SHARE"
        @group i by i.quantile into g
        @select {quantile = key(g), OBS_VALUE = Float64(mean(getproperty(g,Symbol(TIME_PERIOD))))}
        @collect DataFrame
    end
    sp = sortperm([parse(Int,i[2:end]) for i in belgian_distribution.quantile])

    bar!(belgian_distribution.quantile[sp],belgian_distribution.OBS_VALUE[sp],alpha=0.3, label = "Average")

    savefig(joinpath(FIGURE_DIR,"decile_wage_distribution.png"))
end