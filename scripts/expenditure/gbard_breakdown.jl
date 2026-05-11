
let
    df = datasets["gbard"]
    # Using the correct NABS classification as retrieved from Eurostat metadata
    
    nabs_mapping = Dict(
        "NABS01" => "Earth exploration",
        "NABS02" => "Environment",
        "NABS03" => "Space",
        "NABS04" => "Infrastructure/Transport",
        "NABS05" => "Energy",
        "NABS06" => "Industry",
        "NABS07" => "Health",
        "NABS08" => "Agriculture",
        "NABS09" => "Education",
        "NABS10" => "Culture/Media",
        "NABS11" => "Social systems",
        "NABS12" => "Knowledge (GUF)",
        "NABS13" => "Knowledge (Other)",
        "NABS14" => "Defence"
    )

    main_codes = collect(keys(nabs_mapping))
    
    df_eu = @from i in df begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.unit == "MIO_EUR"
        @where i.nabs07 in main_codes
        @select {geo = i.geo, nabs = i.nabs07, value = convert(Float64, getfield(i, Symbol("$TIME_PERIOD")))}
        @collect DataFrame
    end

    # Calculate EU averages
    eu_averages = map(main_codes) do code
        vals = @from i in df_eu begin
            @where i.nabs == code
            @where i.geo != TARGET_ISO
            @select i.value
            @collect
        end
        return (nabs = code, avg_value = sum(vals))
    end |> DataFrame
    
    # Get Belgium data
    be_data = @from i in df_eu begin
        @where i.geo == TARGET_ISO
        @select {nabs = i.nabs, be_value = i.value}
        @collect DataFrame
    end

    # Normalize to percentages
    be_data.be_value = be_data.be_value ./ sum(be_data.be_value) .* 100
    eu_averages.avg_value = eu_averages.avg_value ./ sum(eu_averages.avg_value) .* 100

    joined = innerjoin(be_data, eu_averages, on=:nabs)
    
    # Sort by Belgium value
    sp = reverse(sortperm(joined.be_value))
    sorted_df = joined[sp, :]
    
    labels = [nabs_mapping[c] for c in sorted_df.nabs]
    
    data_matrix = hcat(sorted_df.be_value, sorted_df.avg_value)
    
    spendingplot(labels, data_matrix, ["Belgium", "Europe"], 
        yaxis="Percentage of R&D Budget", 
        title="R&D Budget Breakdown (GBARD)" * get_source("gbard"),
        titlefont=font(10, "Computer Modern"), 
        xrotation=45, 
        bottommargin=20mm,
        leftmargin=10mm,
        size=(1000, 700),
        c=reshape(Plots.palette(:tab10)[[2, 1]], 1, 2))
    
    savefig(joinpath(FIGURE_DIR, "gbard_breakdown.png"))
end
