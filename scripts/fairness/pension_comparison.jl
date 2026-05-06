let
    # 1. Load Pillar 1 data
    df_p1 = datasets["BE_pensionstat_pilar_1"]
    df_p1 = @from i in df_p1 begin
        @where i.Jaar == TIME_PERIOD
        @where i.Pensioentype == "RP"
        @group i by i.Stelsel into g
        @select {Stelsel = key(g), Gemiddeld = sum(g.Aantal.*getproperty(g,Symbol("Gemiddeld bedrag")))/sum(g.Aantal)}
        @collect DataFrame
    end

    df_p1[!,"Netto"] = map(df_p1[!,"Gemiddeld"]) do x
        x <= 1900 && return x
        x <= 3000 && return 0.8*x
        return 0.7*x
    end

    df_p2_wn = datasets["BE_pensionstat_pilar_2_wn"]
    df_p2_wn = @from i in df_p2_wn begin
        @where i.Leeftijdscategorie == "56-65" # leeftijd zo dicht mogelijk bij pensioen
        @where i.Geslacht == "All"
        @where getproperty(i,Symbol("Soort pensioenplan")) == "All"
        @select i
        @collect DataFrame
    end
    
    average_savings_wn = df_p2_wn[1,"Gemiddelde verworven reserve"]
    median_savings_wn =  df_p2_wn[1,"Mediaan verworven reserve"]

    df_p2_zs = datasets["BE_pensionstat_pilar_2_zs"]
    df_p2_zs = @from i in df_p2_zs begin
        @where i.Leeftijdscategorie == "56-65" # leeftijd zo dicht mogelijk bij pensioen
        @where i.Geslacht == "All"
        @where getproperty(i,Symbol("Soort pensioenplan")) == "All"
        @select i
        @collect DataFrame
    end
    
    average_savings_zs = df_p2_zs[1,"Gemiddelde verworven reserve"]
    median_savings_zs =  df_p2_zs[1,"Mediaan verworven reserve"]
    
    # 2. Deficit Analysis
    # 4% Rule: conversion of reserve to yearly annuity, then to monthly amount
    annuity(reserve) = (reserve * 0.04) / 12

    # Extract Netto Pillar 1
    netto_ambtenaar = df_p1[df_p1.Stelsel .== "Ambtenaar", :Netto][1]
    netto_wn = df_p1[df_p1.Stelsel .== "Werknemer", :Netto][1]
    netto_zs = df_p1[df_p1.Stelsel .== "Zelfstandige", :Netto][1]

    # Pillar 2 monthly income (using averages), corrected for lump sump tax
    p2_wn = annuity(median_savings_wn*0.85)
    p2_zs = annuity(median_savings_zs*0.85)

    # Deficit to match Ambtenaar netto
    deficit_wn = netto_ambtenaar - (netto_wn + p2_wn)
    deficit_zs = netto_ambtenaar - (netto_zs + p2_zs)

    # Capital required to bridge the deficit (using 4% rule)
    extra_capital_wn = deficit_wn * 12 / 0.04
    extra_capital_zs = deficit_zs * 12 / 0.04

    # 3. Prepare Plotting Data
    labels = ["Ambtenaar", "Werknemer", "Zelfstandige"]
    p1_vals = [netto_ambtenaar, netto_wn, netto_zs]
    p2_vals = [0.0, p2_wn, p2_zs]
    gap_vals = [0.0, deficit_wn, deficit_zs]

    palette = Plots.palette(:tab10);
    colors = [palette[1] for a in labels]
    p = bar(labels, p1_vals+p2_vals+gap_vals, legend=:bottomright, color=:red, title="Estimated Net Pension" * get_source("BE_pensionstat_pilar_1", "BE_pensionstat_pilar_2_wn", "BE_pensionstat_pilar_2_zs"), yaxis="Estimated Net Pension", xrotation=35, xticks = (0.5:2.5,labels),bottommargin=5mm, label="Deficit",titlefont=font(10,"Computer Modern"),top_margin=15Plots.mm)
    bar!(p,labels,p1_vals+p2_vals, label="Pillar 2", color=palette[2])
    bar!(p,labels,p1_vals,label="Pillar 1", color=palette[1])

    extra_cap_k = round(Int, (gap_vals[2] * 12 / 0.04) / 1000)
    annotate!(1.5, p1_vals[2] + p2_vals[2] + gap_vals[2]/2, text("Deficit: €$(round(Int, gap_vals[2]))/m\nNeed +€$(extra_cap_k)k capital", 8, :bottom, :white))

    extra_cap_k = round(Int, (gap_vals[3] * 12 / 0.04) / 1000)
    annotate!(2.5, p1_vals[3] + p2_vals[3] + gap_vals[3]/2, text("Deficit: €$(round(Int, gap_vals[3]))/m\nNeed +€$(extra_cap_k)k capital", 8, :bottom, :white))

    savefig(joinpath(FIGURE_DIR, "pension_comparison.png"))
end
