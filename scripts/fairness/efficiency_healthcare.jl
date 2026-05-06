let
    df = datasets["hospital_beds"]
    df_beds = @from i in df begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.unit == "P_HTHAB" # per 100 000 inhabitants
        @select {REF_AREA = EUROPEAN_AREA_ISO_NAME[i.geo], beds = convert(Float64,getfield(i,Symbol("$TIME_PERIOD")))}
        @collect DataFrame
    end

    df = datasets["healthy_lifeyears"]
    df_lifeyears = @from i in df begin
        @where i.geo in EUROPEAN_AREA_ISOS
        @where i.sex == "T" # per 100 000 inhabitants
        @where i.indic_he == "HLY_65" # healthy life years at 65
        @select {REF_AREA = EUROPEAN_AREA_ISO_NAME[i.geo], lifeyears = convert(Float64,getfield(i,Symbol("$TIME_PERIOD")))}
        @collect DataFrame
    end

    df = datasets["government_spending_by_function"]
    df_expenditure = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.EXPENDITURE.name == "Health"
        @select {REF_AREA = i.REF_AREA.name, i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    df_expenditure[!,"OBS_VALUE"] .*=10 .^(df_expenditure[!,"UNIT_MULT"].-6)

    df = datasets["gdp"]
    df_gdp = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.UNIT_MEASURE.name == "National currency"
        @select {REF_AREA = i.REF_AREA.name, i.OBS_VALUE, i.UNIT_MULT}
        @collect DataFrame
    end
    df_gdp[!,"OBS_VALUE"] .*=10 .^(df_gdp[!,"UNIT_MULT"].-6)

    full_df = @from i in df_beds begin
        @join j in df_lifeyears on i.REF_AREA equals j.REF_AREA
        @join k in df_expenditure on i.REF_AREA equals k.REF_AREA
        @join l in df_gdp on i.REF_AREA equals l.REF_AREA

        @select {i.REF_AREA, BEDS = i.beds, LIFEYEARS = j.lifeyears, EXPENDITURE = k.OBS_VALUE/l.OBS_VALUE}
        @collect DataFrame
    end

    healthcare_y = hcat(full_df.BEDS,full_df.LIFEYEARS)
    budget_x = full_df.EXPENDITURE
    eff =  efficiency(dea(budget_x,healthcare_y))

    sp = sortperm(eff)
    ref_areas = full_df.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, eff[sp], legend=false, color=colors, title="Healthcare funding efficiency" * get_source("hospital_beds", "healthy_lifeyears", "government_spending_by_function", "gdp"), yaxis="Efficiency healthcare funding", xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm,titlefont=font(10,"Computer Modern"),top_margin=10Plots.mm)
    savefig(joinpath(FIGURE_DIR,"healthcare_efficiency.png"))
end