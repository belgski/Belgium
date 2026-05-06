let
    df_totalrev = datasets["total_government_revenue"]
    df_totalrev = @from i in df_totalrev begin
        @where i.unit == "MIO_EUR"
        @where i.sector == "S13"
        @where i.na_item == "TR"
        @where i.geo in EUROPEAN_AREA_ISOS
        @select {REF_AREA = EUROPEAN_AREA_ISO_NAME[i.geo],val = Float64(getproperty(i,Symbol("$TIME_PERIOD")))}
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

    sp = reverse(sortperm(pie_values))
    belgium_pie = pie_values[sp]
    tax_names_shortened = tax_names_shortened[sp]

    let
        averages = map(tax_codes) do code
            mean((@from i in df begin
                @where i.STANDARD_REVENUE == code

                @select i.OBS_VALUE
                @collect
            end))
        end
        push!(averages,mean(df_totalrev.val)-sum(averages))
        
        eu_pie = averages[sp]

        spendingplot(tax_names_shortened,hcat(belgium_pie./sum(belgium_pie),eu_pie./sum(eu_pie)),["Belgium","Europe"], yaxis="Fraction of total", 
        title="Tax breakdown" *  get_source("total_government_revenue", "government_taxation_revenue"),titlefont=font(10,"Computer Modern"), xrotation=35, bottommargin=10mm,c=reshape(Plots.palette(:tab10)[[2,1]],1,2),top_margin=10mm)
        savefig(joinpath(FIGURE_DIR,"tax_breakdown.png"))

    end
end