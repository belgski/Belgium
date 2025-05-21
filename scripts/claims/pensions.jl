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

# get pension expense / gdp
(df,codelists) = datasets["government_spending_by_function"]
codelist = codelists["CL_COFOG"]
care_budget_code = "GF1002"
@assert codelist[care_budget_code].name == "Old age"
df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"])
care_budget = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE == "XDC"
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.EXPENDITURE == care_budget_code
    @select {REF_AREA = EUROPEAN_AREA_CODE_NAME[i.REF_AREA], i.OBS_VALUE}
    @collect DataFrame
end

(df_gdp,codelists) = datasets["gdp_forecast"]
df_gdp = @from i in df_gdp begin
    @join j in df_gdp on i.LOCATION equals j.LOCATION

    @where i.TIME_PERIOD == TIME_PERIOD
    @where j.TIME_PERIOD == 2060

    @where i.SCENARIO == "S0"
    @where j.SCENARIO == "S0"
    @where i.LOCATION in EUROPEAN_AREA_CODES
    
    @select {REF_AREA=EUROPEAN_AREA_CODE_NAME[i.LOCATION], gdp_now = i.OBS_VALUE, gdp_future = j.OBS_VALUE}
    @collect DataFrame
end

joined = innerjoin(care_budget,df_forecast, df_gdp, on = "REF_AREA")

ratios =  joined.OBS_VALUE ./  joined.gdp_now
#(joined.dependency_future .* joined.OBS_VALUE) ./ (joined.dependency_now .* joined.gdp_now)



sp = sortperm(ratios)
ref_areas = joined.REF_AREA[sp]
ref_area_labels = ref_areas
palette = Plots.palette(:tab10);
colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, ratios[sp], legend=false, yaxis="Price to income ratio",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"future_pension_costs.png"))