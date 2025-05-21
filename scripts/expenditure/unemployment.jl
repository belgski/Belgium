(df,codelists) = datasets["infra_annual_labour"]
codelist = codelists["CL_MEASURE_LFS_TPS"]
df = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @select i
    @collect DataFrame
end
df.OBS_VALUE .*= [10.0^x for x in df.UNIT_MULT]

unempl_rate_code = "UNE_LF"
@assert codelist[unempl_rate_code].name == "Unemployment rate"


unempl_rate_df = @from i in df begin
    @where i.MEASURE == unempl_rate_code
    @select {i.REF_AREA,UNEMPL_RATE = i.OBS_VALUE}
    @collect DataFrame
end


sp = sortperm(unempl_rate_df.UNEMPL_RATE)
ref_areas = unempl_rate_df.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, unempl_rate_df.UNEMPL_RATE[sp], legend=false, yaxis="Unemployment rate",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"unemployment_rate.png"))


unempl_pop_code = "UNE"
@assert codelist[unempl_pop_code].name == "Unemployment"

unempl_pop_df = @from i in df begin
    @where i.MEASURE == unempl_pop_code
    @select {i.REF_AREA,UNEMPL_POP = i.OBS_VALUE}
    @collect DataFrame
end



(df,codelists) = datasets["government_spending_by_function"]
codelist = codelists["CL_COFOG"]
unempl_budget_code = "GF1005"
@assert codelist[unempl_budget_code].name == "Unemployment"

budget = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.EXPENDITURE == unempl_budget_code
    @select i
    @collect DataFrame
end
budget[!,"OBS_VALUE"] .*=10 .^(budget[!,"UNIT_MULT"])


(df,codelists) = datasets["wage_taxation"]
codelist = codelists["CL_INCOME"]
average_income_tax_code = findfirst(v->v.name == "100% of average wage",codelist)
codelist = codelists["CL_MEASURE_TW"]
net_income_code = findfirst(v->v.name == "Net income after taxes",codelist)
codelist = codelists["CL_HOUSEHOLD_TYPE"]
single_person = findfirst(v->v.name == "Single person, no children",codelist)
takehome_pay = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.MEASURE == net_income_code
    @where i.HOUSEHOLD_TYPE == single_person
    @where i.UNIT_MEASURE == "XDC"
    @where i.INCOME_PRINCIPAL == average_income_tax_code
    @select i
    @collect DataFrame
end
takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])

joined = @from i in budget begin
    @join j in unempl_pop_df on i.REF_AREA equals j.REF_AREA
    @join k in takehome_pay on i.REF_AREA equals k.REF_AREA

    @select {i.REF_AREA, BUDGET = i.OBS_VALUE, NUM_UNEMPL = j.UNEMPL_POP , PAY = k.OBS_VALUE}
    @collect DataFrame
end

ratios = joined.BUDGET ./ (joined.NUM_UNEMPL .* joined.PAY)

sp = sortperm(ratios)
ref_areas = joined.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, ratios[sp], legend=false, yaxis="Ratio",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)

savefig(joinpath(FIGURE_DIR,"unemployment_budget_ratio.png"))