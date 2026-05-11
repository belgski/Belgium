let
    df = datasets["price_indices"]
    
    # PLI: Price Level Index (how expensive things are)
    # VI_PPS_HAB: Volume Index per inhabitant (how much people actually buy/can afford)
    
    pli_df = @from i in df begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.ppp_cat == "A01"
        @where i.na_item == "PLI_EU27_2020"
        @select {geo = EUROPEAN_AREA_ISO_NAME[i.geo], pli = convert(Float64,getfield(i,Symbol("$TIME_PERIOD")))}
        @collect DataFrame
    end
    
    vol_df = @from i in df begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.ppp_cat == "A01"
        @where i.na_item == "VI_PPS_EU27_2020_HAB"
        @select {geo = EUROPEAN_AREA_ISO_NAME[i.geo], vol = convert(Float64,getfield(i,Symbol("$TIME_PERIOD")))}
        @collect DataFrame
    end

    df_joined = innerjoin(pli_df, vol_df, on=:geo)
    
    # Sort by price level
    sp = sortperm(df_joined.pli)
    ref_areas = df_joined.geo[sp]
    
    # Create a grouped bar chart
    data = hcat(df_joined.pli[sp], df_joined.vol[sp])
    
    palette = Plots.palette(:tab10);
    colors = reshape([palette[1],palette[2]],(1,2))


    groupedbar(ref_areas, data, 
        label=["Price Level Index" "Volume Index"],
        title="Cost of Living vs Purchasing Power (EU27=100)" * get_source("price_indices"),
        ylabel="Index (EU27 average = 100)",
        xrotation=45,
        c=colors,
        xticks=(1:length(ref_areas), ref_areas),
        bottommargin=10mm,
        size=(800, 500),
        titlefont=font(10, "Computer Modern"),
        legend=:topleft)

    belgium_idx = findfirst(ref_areas .== TARGET_NAME)
    vspan!([belgium_idx-1, belgium_idx], color=palette[3], alpha=0.4, label=false)
    
    savefig(joinpath(FIGURE_DIR, "cost_of_living.png"))
end
