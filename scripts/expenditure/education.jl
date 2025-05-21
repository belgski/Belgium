(df_income,codelists) = datasets["wage_taxation"]
codelist = codelists["CL_INCOME"]
average_income_tax_code = findfirst(v->v.name == "100% of average wage",codelist)
codelist = codelists["CL_MEASURE_TW"]
net_income_code = findfirst(v->v.name == "Net income after taxes",codelist)
gross_income_code = findfirst(v->v.name == "Gross earnings before taxes",codelist)
codelist = codelists["CL_HOUSEHOLD_TYPE"]
single_person = findfirst(v->v.name == "Single person, no children",codelist)

takehome_pay = @from i in df_income begin
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


(df_enrollment_orig,codelists) = datasets["student_enrollment"]
df_enrollment = @from i in df_enrollment_orig begin
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.TIME_PERIOD == TIME_PERIOD
    @select i
    @collect DataFrame
end

codelist = codelists["CL_EDUCATION_LEV_ISCED11"]
early_childhood = findfirst(x->x.name == "Early childhood education" && isnothing(x.parent),codelist)
primary = findfirst(x->x.name == "Primary education" && isnothing(x.parent),codelist)
lower_secondary = findfirst(x->x.name == "Lower secondary education" && isnothing(x.parent),codelist)
upper_secondary = findfirst(x->x.name == "Upper secondary education" && isnothing(x.parent),codelist)
post_secondary_non_tertiary = findfirst(x->x.name == "Post-secondary non-tertiary education" && isnothing(x.parent),codelist)
short_cycle_tertiary = findfirst(x->x.name == "Short-cycle tertiary education" && isnothing(x.parent),codelist)
bachelor = findfirst(x->x.name == "Bachelor’s or equivalent level" && isnothing(x.parent),codelist)
master = findfirst(x->x.name == "Master’s or equivalent level" && isnothing(x.parent),codelist)
phd = findfirst(x->x.name == "Doctoral or equivalent level" && isnothing(x.parent),codelist)
general_lower_secondary = findfirst(x->x.name == "Lower secondary general education",codelist) # used further down the line, as only this category has teacher wages

(df,codelists) = datasets["government_spending_by_function"]
codelist = codelists["CL_COFOG"]
df_spending = @from i in df begin
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.TIME_PERIOD == TIME_PERIOD
    @select i
    @collect DataFrame
end
df_spending[!,"OBS_VALUE"] .*=10 .^(df_spending[!,"UNIT_MULT"])

#-
let
    spending_code = findfirst(x->x.name== "Pre-primary and primary education",codelist)
    grouped = @from i in df_spending begin
        @where i.EXPENDITURE == spending_code

        @join j1 in df_enrollment on i.REF_AREA equals j1.REF_AREA
        @where j1.EDUCATION_LEV == early_childhood
        
        @join j2 in df_enrollment on i.REF_AREA equals j2.REF_AREA
        @where j2.EDUCATION_LEV == primary
        
        @join k in takehome_pay on i.REF_AREA equals k.REF_AREA
        
        @select {i.REF_AREA, BUDGET = i.OBS_VALUE, A = j1.OBS_VALUE * k.OBS_VALUE,B = j2.OBS_VALUE  * k.OBS_VALUE}
        @collect DataFrame
    end

    # correct for missing entries in A
    for row in eachrow(grouped)
        if ismissing(row.A)
            ratio_correct = @from i in df_enrollment_orig begin
                @where i.REF_AREA == row.REF_AREA
                @join j in df_enrollment_orig on i.REF_AREA equals j.REF_AREA
                
                @where i.EDUCATION_LEV == early_childhood
                @where j.EDUCATION_LEV == primary
                
                @where i.TIME_PERIOD == j.TIME_PERIOD

                @select {i.REF_AREA,RATIO = i.OBS_VALUE/j.OBS_VALUE, TIME_DIFF = abs(i.TIME_PERIOD-TIME_PERIOD)}
                @collect DataFrame
            end
            
            mask = (!).(ismissing.(ratio_correct.RATIO))
            ratio_correct = ratio_correct[mask,:]
            ratio = ratio_correct.RATIO[findmin(ratio_correct.TIME_DIFF)[2]]
            row.A = ratio*row.B
            
        end
    end

    ols = lm(@formula(BUDGET ~ A + B), grouped)

    ratios = grouped.BUDGET ./ predict(ols,grouped)
    sp = sortperm(ratios)
    ref_areas = grouped.REF_AREA[sp]
    ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_area_labels, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"pre_primary_education.png"))
end
#--------------
let
    spending_code = findfirst(x->x.name== "Secondary education",codelist)
    grouped = @from i in df_spending begin
        @where i.EXPENDITURE == spending_code

        @join j1 in df_enrollment on i.REF_AREA equals j1.REF_AREA
        @where j1.EDUCATION_LEV == lower_secondary
        
        @join j2 in df_enrollment on i.REF_AREA equals j2.REF_AREA
        @where j2.EDUCATION_LEV == upper_secondary
        
        @join k in takehome_pay on i.REF_AREA equals k.REF_AREA
        
        @select {i.REF_AREA, BUDGET = i.OBS_VALUE, A = j1.OBS_VALUE * k.OBS_VALUE,B = j2.OBS_VALUE  * k.OBS_VALUE}
        @collect DataFrame
    end

    ols = lm(@formula(BUDGET ~ A + B), grouped)

    ratios = grouped.BUDGET ./ predict(ols,grouped)
    sp = sortperm(ratios)
    ref_areas = grouped.REF_AREA[sp]
    ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_area_labels, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"secondary_education.png"))

end

#--------------

let

    spending_code = findfirst(x->x.name== "Tertiary education",codelist)
    grouped = @from i in df_spending begin
        @where i.EXPENDITURE == spending_code

        @join j1 in df_enrollment on i.REF_AREA equals j1.REF_AREA
        @where j1.EDUCATION_LEV == short_cycle_tertiary
        
        @join j2 in df_enrollment on i.REF_AREA equals j2.REF_AREA
        @where j2.EDUCATION_LEV == bachelor

        @join j3 in df_enrollment on i.REF_AREA equals j3.REF_AREA
        @where j3.EDUCATION_LEV == master
        
        @join j4 in df_enrollment on i.REF_AREA equals j4.REF_AREA
        @where j4.EDUCATION_LEV == phd

        @join k in takehome_pay on i.REF_AREA equals k.REF_AREA
        
        @select {i.REF_AREA, BUDGET = i.OBS_VALUE, A = j1.OBS_VALUE * k.OBS_VALUE , B = j2.OBS_VALUE  * k.OBS_VALUE, C = j3.OBS_VALUE  * k.OBS_VALUE , D =  j4.OBS_VALUE  * k.OBS_VALUE}
        #@select i
        @collect DataFrame
    end

    ols = lm(@formula(BUDGET ~ A + B + C + D), grouped)
    ratios = grouped.BUDGET ./ predict(ols,grouped)
    mask = (!).(ismissing.(ratios))
    ratios = ratios[mask]
    sp = sortperm(ratios)
    ref_areas = grouped.REF_AREA[mask][sp]
    ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_area_labels, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"tertiary_education.png"))

end



takehome_pay = @from i in df_income begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.MEASURE == gross_income_code
    @where i.HOUSEHOLD_TYPE == single_person
    @where i.UNIT_MEASURE == "XDC"
    @where i.INCOME_PRINCIPAL == average_income_tax_code
    @select i
    @collect DataFrame
end
takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])

(df_teacher_salary,codelists) = datasets["teacher_salaries"]
@assert all(ismissing.(df_teacher_salary[!,"UNIT_MULT"]))

df_teach_1 = @from i in df_teacher_salary begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @where i.UNIT_MEASURE == "XDC"
    @where i.EDUCATION_LEV == general_lower_secondary
    @select {i.REF_AREA, TEACH_SAL = i.OBS_VALUE}
    @collect DataFrame
end
subregions = findall(codelists["CL_REGIONAL"]) do f
    f.parent in EUROPEAN_AREA_CODES
end
subregion_dict = Dict(s => codelists["CL_REGIONAL"][s].parent for s in subregions)
df_teach_2 = @from i in df_teacher_salary begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where haskey(subregion_dict,i.REF_AREA)
    @where i.EDUCATION_LEV == general_lower_secondary
    @where i.UNIT_MEASURE == "XDC"
    @group i on subregion_dict[i.REF_AREA] into g
    @select {REF_AREA = key(g), TEACH_SAL = sum(g.OBS_VALUE) / length(g.OBS_VALUE)}
    @collect DataFrame
end

df_teach = vcat(df_teach_1,df_teach_2)

joined = innerjoin(df_teach,takehome_pay,on = "REF_AREA")


ratios = joined.TEACH_SAL ./ joined.OBS_VALUE
mask = (!).(ismissing.(ratios))
ratios = ratios[mask]
sp = sortperm(ratios)
ref_areas = joined.REF_AREA[mask][sp]
ref_area_labels = [EUROPEAN_AREA_CODE_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, ratios[sp], legend=false, yaxis="Ratio teacher to average salary",title="Lower secondary school",color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)
savefig(joinpath(FIGURE_DIR,"teacher_salaries.png"))