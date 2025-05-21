let
    df = datasets["immigrant_labour_market_outcome"]

    df = @from i in df begin
        @where i.freq == "A"
        @where i.sex == "T"
        @where i.age == "Y25-64"
        @where i.citizen == "NEU27_2020_FOR"
        @where i.geo in EUROPEAN_AREA_ISOS
        @select {geo = EUROPEAN_AREA_ISO_NAME[i.geo], rate = getfield(i,Symbol("$TIME_PERIOD"))}
        @collect DataFrame
    end

    sp = sortperm(df.rate)
    ref_areas = df.geo[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, df.rate[sp], legend=false, yaxis="Participation rate",color=colors,  xrotation=35 ,xticks = (1:length(ref_areas),ref_areas),bottommargin=10mm)
    savefig(joinpath(FIGURE_DIR,"immigrant_participation_rate.png"))

    df = datasets["immigration_size_statistics"]
    df = @from i in df begin
        @where i.freq == "A"
        @where i.sex == "T"
        @where i.age == "Y15-64"
        @where i.citizen == "NEU27_2020_FOR"
        @where i.geo in EUROPEAN_AREA_ISOS
        @select {geo = EUROPEAN_AREA_ISO_NAME[i.geo], rate = getfield(i,Symbol("$TIME_PERIOD"))}
        @collect DataFrame
    end

    sp = sortperm(df.rate)
    ref_areas = df.geo[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, df.rate[sp], legend=false, yaxis="Immigrant proportion (%)",color=colors,  xrotation=35 ,xticks = (1:length(ref_areas),ref_areas),bottommargin=10mm)
    savefig(joinpath(FIGURE_DIR,"immigrant_proportion.png"))
end