(df, codelist) = datasets["government_taxation_revenue"]

df = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="USD"
    @where i.REF_AREA in EUROPEAN_AREA_CODES
    @select i
    @collect DataFrame
end
df[!,"OBS_VALUE"] .*=10 .^(df[!,"UNIT_MULT"].-6)

df_belgium = @from i in df begin
    @where i.REF_AREA=="BEL"
    @select i
    @collect DataFrame
end

tax_codes = unique(df[!,"STANDARD_REVENUE"])
total_code = findfirst(x->x.name=="Total tax revenue",codelist["CL_STANDARD_REVENUE"])
filter!(tax_codes) do t
    codelist["CL_STANDARD_REVENUE"][t].parent == total_code
end

short = Dict(
    "Taxes on income, profits and capital gains of individuals and corporations"=> "Income/Profit/Capital Gains",
    "Taxes on goods and services"=> "Goods/Services",
    "Other Taxes"=> "Other",
    "Social security contributions (SSC)"=> "Social security",
    "Taxes on payroll and workforce"=> "Payroll/Workforce",
)
tax_names_shortened = map(tax_codes) do x
    p = codelist["CL_STANDARD_REVENUE"][x].name
    if haskey(short,p)
        short[p]
    else
        p
    end
end

let
    pie_values = map(tax_codes) do tx
        df_belgium[df_belgium[!,"STANDARD_REVENUE"].==tx,"OBS_VALUE"][1]
    end


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
end

let
    using Statistics

    df_averaged=deepcopy(df)
    foreach(unique(df_averaged[!,"REF_AREA"])) do country
        country_flt = df_averaged[!,"REF_AREA"].==country
        totaltax = sum(df_averaged[country_flt,"OBS_VALUE"])
        df_averaged[country_flt,"OBS_VALUE"]/=totaltax
    end

    averages = map(tax_codes) do code
        mean((@from i in df_averaged begin
            @where i.STANDARD_REVENUE==code
            @select i
            @collect DataFrame
        end)[!,"OBS_VALUE"])
    end



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