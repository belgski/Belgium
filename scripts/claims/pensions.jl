let
    df = datasets["old_age_dependency_forecast"]

    df = @from i in df begin
        @where i.geo == TARGET_ISO
        @select i
        @collect DataFrame
    end

    years = [parse(Int,x) for x in names(df)[5:end]]
    pl = plot()

    for (scenario,scenario_code) in [("Low migration", "LMIGR"),("Baseline", "BSL"),("High migration","HMIGR")]
        df_scenario = @from i in df begin
            @where i.projection == scenario_code
            @select i
            @collect DataFrame
        end

        plot!(pl,years,Array(df_scenario[1,5:end]),label=scenario)
    end

    savefig(joinpath(FIGURE_DIR,"old_age_dependency_forecast.png"))

    df_forecast = datasets["old_age_dependency_forecast"]
    df_forecast = @from i in df_forecast begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.projection == "BSL"
        @select {REF_AREA = EUROPEAN_AREA_ISO_NAME[i.geo], dependency_now = getfield(i,Symbol("$TIME_PERIOD")), dependency_future = getfield(i,Symbol("2060"))}
        @collect DataFrame
    end


    ratios =  df_forecast.dependency_future ./  df_forecast.dependency_now
    #(joined.dependency_future .* joined.OBS_VALUE) ./ (joined.dependency_now .* joined.gdp_now)



    sp = sortperm(ratios)
    ref_areas = df_forecast.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, tile="Dependency factor increase by 2060",color=colors, yaxis="Dependency then / dependency now", xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"future_pension_costs.png"))
end