(df,codelists) = datasets["house_price_indicators"]
cl = codelists["CL_MEASURE_HOU"]
cod = "HPI_YDH"
@assert cl[cod].name == "Price to income ratio"


df = @from i in df begin
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.TIME_PERIOD == TIME_PERIOD
    @where i.MEASURE == cod
    
    @select i
    @collect DataFrame
end


sp = sortperm(df.OBS_VALUE)
ref_areas = df.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, df.OBS_VALUE[sp], legend=false, yaxis="Price to income ratio",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"housing_affordability.png"))


burden = datasets["housing_overburden_rate"]
burden = @from i in burden begin
    @where i.geo in EUROPEAN_AREA_ISOS
    @where i.deg_urb == "DEG1"
    @select {i.geo, val = getfield(i,Symbol(TIME_PERIOD))}
    @collect DataFrame
end
vals = [isa(v,Float64) ? v : parse(Float64,v) for v in burden.val]
sp = sortperm(vals)
ref_areas = burden.geo[sp]
ref_area_labels = [EUROPEAN_AREA_ISO_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET_ISO ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, vals[sp], legend=false, yaxis="Overburden rate",title="Overburden rate in cities", color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"city_housing_overburden_rate.png"))

burden = datasets["housing_overburden_rate"]
burden = @from i in burden begin
    @where i.geo in EUROPEAN_AREA_ISOS
    @where i.deg_urb == "DEG2"
    @select {i.geo, val = getfield(i,Symbol(TIME_PERIOD))}
    @collect DataFrame
end
vals = [isa(v,Float64) ? v : parse(Float64,v) for v in burden.val]
sp = sortperm(vals)
ref_areas = burden.geo[sp]
ref_area_labels = [EUROPEAN_AREA_ISO_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET_ISO ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, vals[sp], legend=false, yaxis="Overburden rate",title="Overburden rate in towns and suburbs", color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"town_housing_overburden_rate.png"))