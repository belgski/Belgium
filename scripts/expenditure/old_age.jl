
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

(df,codelists) = datasets["population"]
codelist = codelists["CL_AGE"]
old_code = "Y_GE65"
@assert codelist[old_code].name == "65 years or over"
old_people = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.AGE == old_code
    @select i
    @collect DataFrame
end

(df,codelists) = datasets["government_spending_by_function"]
codelist = codelists["CL_COFOG"]
care_budget_code = "GF1002"
@assert codelist[care_budget_code].name == "Old age"

care_budget = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE == "XDC"
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.EXPENDITURE == care_budget_code
    @select i
    @collect DataFrame
end
care_budget[!,"OBS_VALUE"] .*=10 .^(care_budget[!,"UNIT_MULT"])

# group it
grouped = @from i in care_budget begin
    @join j in old_people on i.REF_AREA equals j.REF_AREA
    @join k in takehome_pay on i.REF_AREA equals k.REF_AREA

    @select {i.REF_AREA, CARE_BUDGET = i.OBS_VALUE, NUM_OLD = j.OBS_VALUE , PAY = k.OBS_VALUE}
    @collect DataFrame
end

plot(grouped.CARE_BUDGET,(grouped.NUM_OLD .* grouped.PAY), seriestype=:scatter,xscale=:log10,yscale=:log10,label=false,xaxis="Care budget (national currency)", yaxis = "# old people x average net wage")
savefig(joinpath(FIGURE_DIR,"ratio_test_old_age.png"))

df = DataFrame("X" => (grouped.NUM_OLD .* grouped.PAY), "Y" => grouped.CARE_BUDGET)
ols = lm(@formula(Y ~ X), df)
open(joinpath(FIGURE_DIR,"old_age_r2.txt"),"w") do f
    write(f,sprintf1("%.3g",r2(ols))*".")
end

ratios = df.Y ./ predict(ols,df)

sp = sortperm(ratios)
ref_areas = grouped.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"old_age.png"))