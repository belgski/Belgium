(df,codelists) = datasets["debt"]
df_debt = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @select i
    @collect DataFrame
end


sp = sortperm(df_debt.OBS_VALUE)
ref_areas = df_debt.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, df_debt.OBS_VALUE[sp], legend=false, yaxis="Debt/GDP",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"debt_per_gdp.png"))


(df,codelists) = datasets["government_spending_by_function"]
df = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @select i
    @collect DataFrame
end
df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"])

expenditure_codes = unique(df.EXPENDITURE)
codelist = codelists["CL_COFOG"]
total_code = findfirst(x->x.name=="Total",codelist)
debt_code = findfirst(x->x.name=="Public debt transactions",codelist)

df = @from i in df begin
    @join j in df on i.REF_AREA equals j.REF_AREA
    @where i.EXPENDITURE == total_code
    @where j.EXPENDITURE == debt_code
    @select {i.REF_AREA,TOTAL=i.OBS_VALUE, DEBT = j.OBS_VALUE}
    @collect DataFrame
end

ratios = df.DEBT ./ df.TOTAL .*100

sp = sortperm(ratios)
ref_areas = df.REF_AREA[sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, ratios[sp], legend=false, yaxis="Debt spending/Total %",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"debt_spending.png"))

#=
df = @from i in df begin
    @where i.REF_AREA == "BEL"
    @select i
    @collect DataFrame
end

(df_gov, codelists) = datasets["government_taxation_revenue"]
codelist = codelists["CL_STANDARD_REVENUE"]
invidual_income_gain_profit_tax = "T_1100"
df_gov = @from i in df_gov begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="XDC"
    @where i.REF_AREA == TARGET
    @where i.STANDARD_REVENUE == invidual_income_gain_profit_tax
    @select i
    @collect DataFrame
end
df_gov[!,"OBS_VALUE"] .*=10 .^(df_gov[!,"UNIT_MULT"])


println("halving debt expenditure $((df.DEBT[1]) / df_gov.OBS_VALUE[1] /2 *100)%")
=#