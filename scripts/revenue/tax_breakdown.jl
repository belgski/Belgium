let
    df_totalrev = datasets["total_government_revenue"]
    df_totalrev = @from i in df_totalrev begin
        @where i.unit == "MIO_EUR"
        @where i.sector == "S13"
        @where i.na_item == "TR"
        @where i.geo in EUROPEAN_AREA_ISOS
        @select {REF_AREA = EUROPEAN_AREA_ISO_NAME[i.geo],val = getproperty(i,Symbol("$TIME_PERIOD"))}
        @collect DataFrame
    end

    df = datasets["government_taxation_revenue"]
    flt = intersect([d.name for d in df.REF_AREA],df_totalrev.REF_AREA)

    df_totalrev = @from i in df_totalrev begin
        @where i.REF_AREA in flt
        @select i
        @collect DataFrame
    end

    df = @from i in df begin
        @where i.TIME_PERIOD == TIME_PERIOD
        @where i.UNIT_MEASURE.name == "National currency"
        @where i.REF_AREA.name in flt
        @select i
        @collect DataFrame
    end
    df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"].-6)
    
    df_belgium = @from i in df begin
        @where i.REF_AREA.name==TARGET_NAME
        @select i
        @collect DataFrame
    end

    tax_codes = unique(df[!,"STANDARD_REVENUE"])
    filter!(tax_codes) do t
        t.parent == "Total tax revenue"
    end

    short = Dict(
        "Taxes on income, profits and capital gains of individuals and corporations"=> "Income/Profit/Capital Gains",
        "Taxes on goods and services"=> "Goods/Services",
        "Other Taxes"=> "Other",
        "Social security contributions (SSC)"=> "Social security",
        "Taxes on payroll and workforce"=> "Payroll/Workforce",
    )
    tax_names_shortened = map(tax_codes) do x
        get(short,x.name,x.name)
    end
    
    pie_values = map(tax_codes) do tx
        df_belgium[[d == tx for d in df_belgium[!,"STANDARD_REVENUE"]],"OBS_VALUE"][1]
    end
    
    push!(pie_values,sum(df_totalrev.val[df_totalrev.REF_AREA.==TARGET_NAME])-sum(pie_values))
    push!(tax_names_shortened,"Non tax revenue")

    sp = sortperm(pie_values)
    pie_values = pie_values[sp]
    tax_names_shortened = tax_names_shortened[sp]

    tot = sum(pie_values)
    percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]

    θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
    scθ = sincosd.(θ)

    using Plots.Measures
    p = pie(tax_names_shortened,pie_values,right_margin=40mm,legend=(1,0.5))
    for (i,(s, sci)) in enumerate(zip(percentages, scθ))
        annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
    end
    p


    savefig(joinpath(FIGURE_DIR,"tax_breakdown_belgium.png"))

    let
            averages = map(tax_codes) do code
            mean((@from i in df begin
                @where i.STANDARD_REVENUE == code

                @select i.OBS_VALUE
                @collect
            end))
        end
        push!(averages,
            mean(df_totalrev.val)-sum(averages))
        
        averages = averages[sp]


        tot = sum(averages)

        percentages = [sprintf1("%0.1f",x)*"%" for x in averages./tot*100]

        θ = (cumsum(averages) - averages/2) .* 360/sum(averages)
        scθ = sincosd.(θ)

        p = pie(averages,legend=false)
        for (s, sci) in zip(percentages, scθ)
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end

        savefig(joinpath(FIGURE_DIR,"tax_breakdown_average.png"))

    end
end