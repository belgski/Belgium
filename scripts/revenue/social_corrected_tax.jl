(df, codelists) = datasets["government_taxation_revenue"]
codelist = codelists["CL_STANDARD_REVENUE"]
total_code = findfirst(x->x.name=="Total tax revenue",codelist)

df = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="USD"
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @select i
    @collect DataFrame
end
df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"].-6)

tax_codes = unique(df[!,"STANDARD_REVENUE"])
social_security_code_index = findfirst(x-> codelist[x].name == "Social security contributions (SSC)", tax_codes)
ssc = tax_codes[social_security_code_index]
@assert codelist[ssc].parent == total_code
filter!(tax_codes) do tx
    codelist[ssc].parent == codelist[tx].parent
end

tax_rev_ssc_adjusted = @from i in df begin
    @where i.STANDARD_REVENUE != ssc
    @where i.STANDARD_REVENUE in tax_codes
    @group i by i.REF_AREA into g
    @select {REF_AREA=key(g),TAX=sum(g.OBS_VALUE)}
    @collect DataFrame
end


(df, codelist) = datasets["gdp"]
gdp = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES

    @where i.UNIT_MEASURE == "USD"
    @select {i.REF_AREA,i.OBS_VALUE,i.UNIT_MULT}
    @collect DataFrame
end
gdp = rename(gdp,("OBS_VALUE" => "GDP"))
gdp[!,"GDP"] .*=10 .^(gdp[!,"UNIT_MULT"].-6)
belgium_gdp = gdp[gdp[!,"REF_AREA"] .== TARGET,"GDP"]

joined = innerjoin(tax_rev_ssc_adjusted,gdp,on = "REF_AREA")

pl = histogram(joined.TAX./joined.GDP .*100,xlim=(0,40),legend=false, yaxis= "# countries", xaxis = "taxation revenue - SSC over gdp",bins=0:5:100)
bel_entry = joined[joined[!,"REF_AREA"].=="BEL",:]
vline!(bel_entry.TAX./bel_entry.GDP .*100)
savefig(joinpath(FIGURE_DIR,"social_corrected_tax.png"))

taxation_per_gdp = joined.TAX./joined.GDP

sp = sortperm(taxation_per_gdp)
ref_areas = joined.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, taxation_per_gdp[sp], legend=false, yaxis="taxation revenue - SSC per gdp",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"social_corrected_tax.png"))