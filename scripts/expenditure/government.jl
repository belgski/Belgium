(df,codelists) = datasets["government_spending_by_function"]
codelist = codelists["CL_COFOG"]
gov_spending_code ="GF09"
@assert codelist[gov_spending_code].name == "Education"
gov_spending_df = @from i in df begin
    @where i.TIME_PERIOD == TIME_PERIOD
    @where i.EXPENDITURE == gov_spending_code
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @select i
    @collect DataFrame
end
gov_spending_df[!,"OBS_VALUE"] .*=10 .^(gov_spending_df[!,"UNIT_MULT"])

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
total_code = "_T"
@assert codelists["CL_AGE"][total_code].name == "Total"
total_pop = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.AGE == total_code
    @select i
    @collect DataFrame
end
total_pop[!,"OBS_VALUE"] .*=10 .^(total_pop[!,"UNIT_MULT"])

joined = @from i in gov_spending_df begin
    @join j in total_pop on i.REF_AREA equals j.REF_AREA
    @join k in takehome_pay on i.REF_AREA equals k.REF_AREA

    @select {i.REF_AREA, BUDGET = i.OBS_VALUE, NUM_POP = j.OBS_VALUE , PAY = k.OBS_VALUE}
    @collect DataFrame
end


ratios = joined.BUDGET ./ (joined.NUM_POP .* joined.PAY)

sp = sortperm(ratios)
ref_areas = joined.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, ratios[sp], legend=false, yaxis="Ratio",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)

savefig(joinpath(FIGURE_DIR,"gov_budget.png"))


df = DataFrame("X" => (joined.NUM_POP .* joined.PAY), "Y" => joined.BUDGET)
ols = lm(@formula(Y ~ X), df)
open(joinpath(FIGURE_DIR,"government_r2.txt"),"w") do f
    write(f,sprintf1("%.3g",r2(ols))*".")
end

#=
savings = joined.BUDGET[joined.REF_AREA.=="BEL"][1] * 1/3
(df, codelists) = datasets["government_taxation_revenue"]
codelist = codelists["CL_STANDARD_REVENUE"]
invidual_income_gain_profit_tax = "T_1100"
df = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="XDC"
    @where i.REF_AREA == TARGET
    @where i.STANDARD_REVENUE == invidual_income_gain_profit_tax
    @select i
    @collect DataFrame
end
df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"])

bar(["Government spending","Individual income gain tax"],[joined.BUDGET[joined.REF_AREA.=="BEL"][1],df.OBS_VALUE[1]])
savefig(joinpath(FIGURE_DIR,"government_scale.png"))

println("lowering government spending would decrease individual tax by $(savings/df.OBS_VALUE[1]*100)%")
=#