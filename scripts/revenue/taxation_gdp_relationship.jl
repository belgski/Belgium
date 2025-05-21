let
    df = datasets["government_taxation_revenue"]
    taxation_USD = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.UNIT_MEASURE.name =="US dollar"
        @where i.STANDARD_REVENUE.name == "Total tax revenue"
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES

        @select {REF_AREA = i.REF_AREA.name,i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    taxation_USD = rename(taxation_USD,("OBS_VALUE" => "TOTALTAX"))
    taxation_USD[!,"TOTALTAX"].*=10 .^(taxation_USD[!,"UNIT_MULT"].-6)
    belgium_taxation = taxation_USD[taxation_USD[!,"REF_AREA"] .== TARGET_NAME,"TOTALTAX"]

    df = datasets["gdp"]
    gdp = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES

        @where i.UNIT_MEASURE.name =="US dollar"
        @select {REF_AREA = i.REF_AREA.name,i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    gdp = rename(gdp,("OBS_VALUE" => "GDP"))
    gdp[!,"GDP"] .*=10 .^(gdp[!,"UNIT_MULT"].-6)
    belgium_gdp = gdp[gdp[!,"REF_AREA"] .== TARGET_NAME,"GDP"]

    joined = innerjoin(taxation_USD,gdp,on = "REF_AREA",makeunique=true)
    taxation_per_gdp = joined.TOTALTAX ./ joined.GDP


    sp = sortperm(taxation_per_gdp)
    ref_areas = joined.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, taxation_per_gdp[sp], legend=false, yaxis="Taxation over GDP",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)

    savefig(joinpath(FIGURE_DIR,"taxation_per_gdp.png"))

    plot(joined.TOTALTAX,joined.GDP,seriestype=:scatter,xscale=:log10,yscale=:log10,legend=false,xaxis="Tax revenue (million USD)", yaxis="GDP (million USD)")
    plot!(belgium_taxation,belgium_gdp,seriestype=:scatter)

    using Statistics
    median_rico = median(joined.TOTALTAX./joined.GDP)
    gdp_line = [10.0^i for i in  1:0.1:7]
    tax_line = [median_rico*g for g in gdp_line]

    plot!(tax_line,gdp_line)

    savefig(joinpath(FIGURE_DIR,"taxation_gdp_relationship.png"))
end