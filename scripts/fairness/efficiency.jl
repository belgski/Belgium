let 
    df_pisa = datasets["pisa"]
    df_pisa = @from i in df_pisa begin
        @where i.country in EUROPEAN_AREA_ISO3S
        @where i.year == TIME_PERIOD
        @group i by i.country into g
        @select {REF_AREA = EUROPEAN_AREA_ISO3_NAME[key(g)], math = sum(g.math .* g.stu_wgt)/sum(g.stu_wgt), read = sum(g.read .* g.stu_wgt)/sum(g.stu_wgt), science = sum(g.science .* g.stu_wgt)/sum(g.stu_wgt)}
        @collect DataFrame
    end

    df = datasets["government_spending_by_function"]
    df_spending = @from i in df begin
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.EXPENDITURE.name in ["Pre-primary and primary education", "Secondary education"]
        @select {REF_AREA = i.REF_AREA.name,EXPENDITURE = i.EXPENDITURE.name, i.OBS_VALUE,i.UNIT_MULT, i.TIME_PERIOD}
        @collect DataFrame
    end
    df_spending[!,"OBS_VALUE"] .*=10 .^(df_spending[!,"UNIT_MULT"])
    df_spending = @from i in df_spending begin
        @join j in df_spending on i.REF_AREA equals j.REF_AREA
        @where i.TIME_PERIOD == j.TIME_PERIOD
        
        @where i.EXPENDITURE == "Pre-primary and primary education"
        @where j.EXPENDITURE ==  "Secondary education"
        @select {REF_AREA = i.REF_AREA, primary = i.OBS_VALUE, secondary = j.OBS_VALUE, i.TIME_PERIOD}
        @collect DataFrame
    end

    # now get the enrollments
    # this is complicated by the fact that some countries don't report pre-primary enrollments
    df_enrollment_orig = datasets["student_enrollment"]
    df_enrollment = @from i in df_enrollment_orig begin
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select {REF_AREA = i.REF_AREA.name, EDUCATION_LEV = i.EDUCATION_LEV.name, i.OBS_VALUE, i.TIME_PERIOD}
        @collect DataFrame
    end
    df_enrollment_secondary = @from i in df_enrollment begin
        @join j in df_enrollment on i.REF_AREA equals j.REF_AREA
        @where i.TIME_PERIOD == j.TIME_PERIOD
        @where i.EDUCATION_LEV == "Lower secondary education"
        @where j.EDUCATION_LEV == "Upper secondary education"
        @select {REF_AREA = i.REF_AREA, secondary = i.OBS_VALUE+j.OBS_VALUE, i.TIME_PERIOD}
        @collect DataFrame
    end
    df_enrollment_pre_primary = @from i in df_enrollment begin
        @join j in df_enrollment on i.REF_AREA equals j.REF_AREA

        @where i.TIME_PERIOD == j.TIME_PERIOD
        @where i.EDUCATION_LEV == "Early childhood education"
        @where j.EDUCATION_LEV == "Primary education"

        @select {REF_AREA = i.REF_AREA, pre_primary = i.OBS_VALUE, primary = j.OBS_VALUE,i.TIME_PERIOD}
        @collect DataFrame

    end

    # correct for missing entries in df_enrollment
    for row in eachrow(df_enrollment_pre_primary)
        if ismissing(row.pre_primary) 
            ratio_correct = @from i in df_enrollment_pre_primary begin

                @where i.REF_AREA == row.REF_AREA            
                @select {i.REF_AREA,RATIO = i.pre_primary/i.primary, TIME_DIFF = abs(i.TIME_PERIOD-row.TIME_PERIOD)}
                @collect DataFrame
            end
            
            mask = (!).(ismissing.(ratio_correct.RATIO))
            ratio_correct = ratio_correct[mask,:]
            ratio = ratio_correct.RATIO[findmin(ratio_correct.TIME_DIFF)[2]]
            row.pre_primary = ratio*row.primary
            
        end
    end

    df_enrollment = @from i in df_enrollment_pre_primary begin
        @join j in df_enrollment_secondary on i.REF_AREA equals j.REF_AREA
        @where i.TIME_PERIOD == j.TIME_PERIOD
        @select {REF_AREA = i.REF_AREA, pre_primary = i.pre_primary + i.primary, secondary = j.secondary, i.TIME_PERIOD}
        @collect DataFrame
    end

    #df_enrollment is now the number of students enrolled in pre-primary+primary and secondary education

    df = datasets["wage_taxation"]
    takehome_pay = @from i in df begin
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.MEASURE.name == "Gross earnings before taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @where i.UNIT_MEASURE.name =="National currency"
        @where i.HOUSEHOLD_TYPE.name == "Single person, no children"
        @select {REF_AREA = i.REF_AREA.name ,i.OBS_VALUE, i.UNIT_MULT, i.TIME_PERIOD}
        @collect DataFrame
    end
    takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])

    joined_df = @from i in df_enrollment begin
        @join j in df_spending on i.REF_AREA equals j.REF_AREA
        @join l in takehome_pay on i.REF_AREA equals l.REF_AREA
        @where i.TIME_PERIOD == j.TIME_PERIOD
        @where i.TIME_PERIOD == l.TIME_PERIOD

        @select {i.REF_AREA, PRE_BUDGET = j.primary/i.pre_primary / l.OBS_VALUE, SECONDARY_BUDGET = j.secondary/i.secondary / l.OBS_VALUE, i.TIME_PERIOD}
        @collect DataFrame
    end
    
    pre_primary_investment = @from pre_primary in joined_df begin
        # investement in pre-primary education ends 4 years before testing, starts 12 years before that (3 years pre-primary, 6 years primary, 4 years secondary)
        @where pre_primary.TIME_PERIOD >= TIME_PERIOD - 12
        @where pre_primary.TIME_PERIOD <= TIME_PERIOD - 4

        @group pre_primary by pre_primary.REF_AREA into g
        @select {REF_AREA = key(g), investment = sum(g.PRE_BUDGET)}
    end

    secondary_investment = @from secondary in joined_df begin
        # investement in pre-primary education ends 4 years before testing, starts 12 years before that (3 years pre-primary, 6 years primary, 4 years secondary)
        @where secondary.TIME_PERIOD >= TIME_PERIOD -3
        @where secondary.TIME_PERIOD <= TIME_PERIOD

        @group secondary by secondary.REF_AREA into g
        @select {REF_AREA = key(g), investment = sum(g.SECONDARY_BUDGET)}
    end
    input_df = @from i in pre_primary_investment begin
        @join j in secondary_investment on i.REF_AREA equals j.REF_AREA
        @select {i.REF_AREA, BUDGET = i.investment + j.investment}
        @collect DataFrame
    end

    # do an efficiency analysis using JuMP
    full_df = @from i in input_df begin
        @join j in df_pisa on i.REF_AREA equals j.REF_AREA
        @select {i.REF_AREA, i.BUDGET, j.math, j.read, j.science}
        @collect DataFrame
    end
    pisa_y = hcat(full_df.math,full_df.read,full_df.science)
    budget_x = full_df.BUDGET
    eff =  efficiency(dea(budget_x,pisa_y))

    sp = sortperm(eff)
    ref_areas = full_df.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, eff[sp], legend=false, color=colors, yaxis="Efficiency education funding", xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"education_efficiency.png"))
end


