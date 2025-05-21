(df,codelists) = datasets["well_being"]
happy_code = findfirst(x-> x.name == "Life satisfaction",codelists["CL_MEASURE"])
region_translation = codelists["CL_REGIONAL"]

df = @from i in df begin
    @where i.MEASURE == happy_code
    @where i.SEX == "_T"
    @where i.AGE == "_T"
    @where i.EDUCATION_LEV == "_T"
    @select {COUNTRY = region_translation[i.REF_AREA].name, i.OBS_VALUE}
    @collect DataFrame
end



sp = sortperm(df.OBS_VALUE)[end-25:end]
ref_areas = df.COUNTRY[sp]
palette = Plots.palette(:tab10);
colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]

# it is not important to be able to read of every single quized country
bar(ref_areas, df.OBS_VALUE[sp], legend=false, yaxis="Life statistfaction (out of 10)",color=colors,  xrotation=35 ,xticks = (1:length(ref_areas),ref_areas),bottommargin=10mm,title = "Twenty-five happiest countries in the world")
savefig(joinpath(FIGURE_DIR,"life_statisfaction.png"))