(df, codelists) = datasets["wage_taxation"]
codelist = codelists["CL_HOUSEHOLD_TYPE"]
single_person = findfirst(v->v.name == "Single person, no children",codelist)

df = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="USD_PPP"
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.HOUSEHOLD_TYPE == single_person
    @select i
    @collect DataFrame
end

codelist = codelists["CL_INCOME"]
average_income_tax_code = findfirst(v->v.name == "100% of average wage",codelist)
high_income_tax_code = findfirst(v->v.name == "167% of average wage",codelist)

codelist = codelists["CL_MEASURE_TW"]
gross_labour_cost_code = findfirst(v->v.name == "Gross labour costs before taxes",codelist)
net_income_code = findfirst(v->v.name == "Net income after taxes",codelist)


df_gross_labour = @from i in df begin
    @where i.MEASURE==gross_labour_cost_code
    @where i.INCOME_PRINCIPAL==average_income_tax_code
    @select {i.REF_AREA,i.OBS_VALUE}
    @collect DataFrame
end
df_gross_labour = rename(df_gross_labour,("OBS_VALUE" => "GROSS_LABOUR"))


df_net_income = @from i in df begin
    @where i.MEASURE==net_income_code
    @where i.INCOME_PRINCIPAL==average_income_tax_code
    @select {i.REF_AREA,i.OBS_VALUE}
    @collect DataFrame
end

df_net_income = rename(df_net_income,("OBS_VALUE" => "NET_INCOME"))

joined = innerjoin(df_gross_labour,df_net_income,on = "REF_AREA",makeunique=true)

histogram(joined[!,"NET_INCOME"]./joined[!,"GROSS_LABOUR"] .*100 ,xaxis="(net income)/(gross labour cost) %",yaxis="# of countries",bins = 40:2:70,alpha=0.2,label="average wage")
belgium_row = joined[joined[!,"REF_AREA"] .== "BEL",:]

vline!([belgium_row[1,"NET_INCOME"]/belgium_row[1,"GROSS_LABOUR"] * 100],color=:blue,label=false)


df_gross_labour = @from i in df begin
    @where i.MEASURE==gross_labour_cost_code
    @where i.INCOME_PRINCIPAL==high_income_tax_code
    @select {i.REF_AREA,i.OBS_VALUE}
    @collect DataFrame
end
df_gross_labour = rename(df_gross_labour,("OBS_VALUE" => "GROSS_LABOUR"))


df_net_income = @from i in df begin
    @where i.MEASURE==net_income_code
    @where i.INCOME_PRINCIPAL==high_income_tax_code
    @select {i.REF_AREA,i.OBS_VALUE}
    @collect DataFrame
end
df_net_income = rename(df_net_income,("OBS_VALUE" => "NET_INCOME"))

joined = innerjoin(df_gross_labour,df_net_income,on = "REF_AREA",makeunique=true)

histogram!(joined[!,"NET_INCOME"]./joined[!,"GROSS_LABOUR"] .*100,bins = 40:2:70,alpha=0.2,label="high wage")


belgium_row = joined[joined[!,"REF_AREA"] .== "BEL",:]
vline!([belgium_row[1,"NET_INCOME"]/belgium_row[1,"GROSS_LABOUR"] * 100],label=false,color=:green)
savefig(joinpath(FIGURE_DIR,"net_income_vs_gross_labour.png"))
