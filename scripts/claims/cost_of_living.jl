let
    df = datasets["price_indices"]
    #[A0101] Code : a 0101 . Food and non-alcoholic beverages
    #[A0103] Code : a 0103 . Clothing and footwear
    #[A0104] Housing, water, electricity, gas and other fuels
    df = @from i in df begin

        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.ppp_cat == "A01"
        @where i.na_item == "PPP_EU27_2020"
        @select {geo = EUROPEAN_AREA_ISO_NAME[i.geo], rate = convert(Float64,getfield(i,Symbol("$TIME_PERIOD")))}
        @collect DataFrame
    end

    

    sp = sortperm(df.rate)
    ref_areas = df.geo[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, df.rate[sp], legend=false, title="Per capita expenditure on goods and services" * get_source("price_indices"),color=colors, yaxis="Purchasing Power Parity converted", xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm,titlefont=font(10,"Computer Modern"))
    savefig(joinpath(FIGURE_DIR,"cost_of_living.png"))
end