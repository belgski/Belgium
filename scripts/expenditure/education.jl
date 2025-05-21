let
    df = datasets["wage_taxation"]
    takehome_pay = @from i in df begin
        @where i.TIME_PERIOD == TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.MEASURE.name == "Net income after taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @where i.UNIT_MEASURE.name =="National currency"
        @where i.HOUSEHOLD_TYPE.name == "Single person, no children"
        @select {REF_AREA = i.REF_AREA.name ,i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])


    df_enrollment_orig = datasets["student_enrollment"]
    df_enrollment = @from i in df_enrollment_orig begin
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.TIME_PERIOD == TIME_PERIOD
        @select {REF_AREA = i.REF_AREA.name, EDUCATION_LEV = i.EDUCATION_LEV.name, i.OBS_VALUE}
        @collect DataFrame
    end


    df = datasets["government_spending_by_function"]
    df_spending = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select {REF_AREA = i.REF_AREA.name,EXPENDITURE = i.EXPENDITURE.name, i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    df_spending[!,"OBS_VALUE"] .*=10 .^(df_spending[!,"UNIT_MULT"])

    #-
    let
        grouped = @from i in df_spending begin
            @where i.EXPENDITURE == "Pre-primary and primary education"

            @join j1 in df_enrollment on i.REF_AREA equals j1.REF_AREA
            @where j1.EDUCATION_LEV == "Early childhood education"
            
            @join j2 in df_enrollment on i.REF_AREA equals j2.REF_AREA
            @where j2.EDUCATION_LEV == "Primary education"
            
            @join k in takehome_pay on i.REF_AREA equals k.REF_AREA
            
            @select {i.REF_AREA, BUDGET = i.OBS_VALUE, A = j1.OBS_VALUE * k.OBS_VALUE,B = j2.OBS_VALUE  * k.OBS_VALUE}
            @collect DataFrame
        end

        # correct for missing entries in A
        for row in eachrow(grouped)
            if ismissing(row.A)
                ratio_correct = @from i in df_enrollment_orig begin

                    @where i.REF_AREA.name == row.REF_AREA
                    @join j in df_enrollment_orig on i.REF_AREA equals j.REF_AREA
                    
                    @where i.EDUCATION_LEV.name == "Early childhood education"
                    @where j.EDUCATION_LEV.name == "Primary education"
                    
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
        palette = Plots.palette(:tab10);
        colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
        bar(ref_areas, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
        savefig(joinpath(FIGURE_DIR,"pre_primary_education.png"))
    end
    #--------------
    let
        grouped = @from i in df_spending begin
            @where i.EXPENDITURE == "Secondary education"

            @join j1 in df_enrollment on i.REF_AREA equals j1.REF_AREA
            @where j1.EDUCATION_LEV == "Lower secondary education"
            
            @join j2 in df_enrollment on i.REF_AREA equals j2.REF_AREA
            @where j2.EDUCATION_LEV == "Upper secondary education"
            
            @join k in takehome_pay on i.REF_AREA equals k.REF_AREA
            
            @select {i.REF_AREA, BUDGET = i.OBS_VALUE, A = j1.OBS_VALUE * k.OBS_VALUE,B = j2.OBS_VALUE  * k.OBS_VALUE}
            @collect DataFrame
        end


        ols = lm(@formula(BUDGET ~ A + B), grouped)

        ratios = grouped.BUDGET ./ predict(ols,grouped)
        sp = sortperm(ratios)
        ref_areas = grouped.REF_AREA[sp]
        palette = Plots.palette(:tab10);
        colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
        bar(ref_areas, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
        savefig(joinpath(FIGURE_DIR,"secondary_education.png"))

    end


    df = datasets["wage_taxation"]
    takehome_pay = @from i in df begin
        @where i.TIME_PERIOD == TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.MEASURE.name == "Gross earnings before taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @where i.UNIT_MEASURE.name =="National currency"
        @where i.HOUSEHOLD_TYPE.name == "Single person, no children"
        @select {REF_AREA = i.REF_AREA.name ,i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    takehome_pay[!,"OBS_VALUE"] .*=10 .^(takehome_pay[!,"UNIT_MULT"])


    df_teacher_salary = datasets["teacher_salaries"]

    df_teach_1 = @from i in df_teacher_salary begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.UNIT_MEASURE.name == "National currency"
        @where i.EDUCATION_LEV.name == "Lower secondary general education"
        @select {REF_AREA = i.REF_AREA.name, TEACH_SAL = i.OBS_VALUE}
        @collect DataFrame
    end

    df_teach_2 = @from i in df_teacher_salary begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.parent in EUROPEAN_AREA_NAMES
        @where i.UNIT_MEASURE.name == "National currency"
        @where i.EDUCATION_LEV.name == "Lower secondary general education"

        @group i on i.REF_AREA.parent into g

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
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, yaxis="Ratio teacher to average salary",title="Lower secondary school",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"teacher_salaries.png"))
end