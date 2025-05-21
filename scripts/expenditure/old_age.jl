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



    df = datasets["population"]
    old_people = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.AGE.name == "65 years or over"
        @select {REF_AREA = i.REF_AREA.name, i.OBS_VALUE,i.UNIT_MULT}
        @collect DataFrame
    end
    old_people[!,"OBS_VALUE"] .*=10 .^(old_people[!,"UNIT_MULT"])

    df = datasets["government_spending_by_function"]
    care_budget = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.EXPENDITURE.name == "Old age"
        @select {REF_AREA = i.REF_AREA.name,i.OBS_VALUE,i.UNIT_MULT}
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
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, ratios[sp], legend=false, yaxis="Actual/estimated budget",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm)
    savefig(joinpath(FIGURE_DIR,"old_age.png"))
end