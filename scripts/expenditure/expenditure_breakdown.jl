let
    (df,codelists) = datasets["government_spending_by_function"]

    df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
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
    expenditure_codes = unique(df_belgium.EXPENDITURE)
    codelist = codelists["CL_COFOG"]
    total_code = findfirst(x->x.name=="Total",codelist)
    lvl_1_codes = expenditure_codes[findall(x->codelist[x].parent == total_code,expenditure_codes)]
    lvl_1_names = [codelist[x].name for x in lvl_1_codes]

    df_eu=deepcopy(df)

    foreach(unique(df_eu[!,"REF_AREA"])) do country
        country_flt = df_eu[!,"REF_AREA"].==country
        totaltax = sum(df_eu[country_flt,"OBS_VALUE"])
        df_eu[country_flt,"OBS_VALUE"]/=totaltax
    end


    shortened = Dict("Public order and safety"=> "Order/safety",
                    "Recreation, culture and religion" => "Recreation/culture", #religion is a piece of culture no?
                    "Housing and community amenities" => "Housing/community amenities")
    lvl_1_shortened_names = map(lvl_1_names) do k
        haskey(shortened,k) ? shortened[k] : k
    end


    let
        pie_values = map(lvl_1_codes) do tx
            df_belgium[df_belgium[!,"EXPENDITURE"].==tx,"OBS_VALUE"][1]
        end
        sp = reverse(sortperm(pie_values))
        lvl_1_shortened_names = lvl_1_shortened_names[sp]
        lvl_1_names = lvl_1_names[sp]
        lvl_1_codes = lvl_1_codes[sp]
        pie_values = pie_values[sp]

        tot = sum(pie_values)
        


        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]
        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(lvl_1_shortened_names,pie_values,right_margin=60mm,legend=(1.1,0.8))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"spend_breakdown_belgium.png"))

        averages = map(lvl_1_codes) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE==code
                @select i
                @collect DataFrame
            end)[!,"OBS_VALUE"])
        end

        pie_values = map(lvl_1_codes) do tx
            df_eu[df_eu[!,"EXPENDITURE"].==tx,"OBS_VALUE"][1]
        end
        pie_values
        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]


        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        p = pie(lvl_1_shortened_names,pie_values,legend=false)#,right_margin=40mm,legend=(1,0.5))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black,halign = :center))
        end
        p


        savefig(joinpath(FIGURE_DIR,"spend_breakdown_average.png"))
    end

    let
        social_protection_code = lvl_1_codes[findfirst(==("Social protection"),lvl_1_names)]
        social_protection_subcategories = filter(expenditure_codes) do x
            codelist[x].parent == social_protection_code
        end

        social_protection_subcategories_names = [codelist[x].name for x in social_protection_subcategories]
        pie_values = map(social_protection_subcategories) do tx
            df_belgium[df_belgium[!,"EXPENDITURE"].==tx,"OBS_VALUE"][1]
        end
        sp = reverse(sortperm(pie_values))
        social_protection_subcategories = social_protection_subcategories[sp]
        social_protection_subcategories_names = social_protection_subcategories_names[sp]
        pie_values = pie_values[sp]


        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]
        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(social_protection_subcategories_names,pie_values,right_margin=60mm,legend=(1.1,0.8))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"social_protection_belgium.png"))

        averages = map(social_protection_subcategories) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE==code
                @select i
                @collect DataFrame
            end)[!,"OBS_VALUE"])
        end

        tot = sum(averages)
        percentages = [sprintf1("%0.1f",x)*"%" for x in averages./tot*100]
        θ = (cumsum(averages) - averages/2) .* 360/sum(averages)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(social_protection_subcategories_names,averages,legend=false)
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"social_protection_eu.png"))
    end


    let
        social_protection_code = lvl_1_codes[findfirst(==("General public services"),lvl_1_names)]
        social_protection_subcategories = filter(expenditure_codes) do x
            codelist[x].parent == social_protection_code
        end

        shortened_sp = Dict("R&D General public services"=> "R&D",
                    "Executive and legislative organs, financial and fiscal affairs, external affairs" => "Greedy government",
                    "Transfers of a general character between different levels of government" => "Intra-government transfers")

        social_protection_subcategories_names = [codelist[x].name for x in social_protection_subcategories]
        social_protection_subcategories_names = [get(shortened_sp,x,x) for x in social_protection_subcategories_names]
        
        pie_values = map(social_protection_subcategories) do tx
            df_belgium[df_belgium[!,"EXPENDITURE"].==tx,"OBS_VALUE"][1]
        end
        sp = reverse(sortperm(pie_values))
        social_protection_subcategories = social_protection_subcategories[sp]
        social_protection_subcategories_names = social_protection_subcategories_names[sp]
        pie_values = pie_values[sp]


        
        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]
        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(social_protection_subcategories_names,pie_values,right_margin=60mm,legend=(1.1,0.8))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"public_services_belgium.png"))

        averages = map(social_protection_subcategories) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE==code
                @select i
                @collect DataFrame
            end)[!,"OBS_VALUE"])
        end

        tot = sum(averages)
        percentages = [sprintf1("%0.1f",x)*"%" for x in averages./tot*100]
        θ = (cumsum(averages) - averages/2) .* 360/sum(averages)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(social_protection_subcategories_names,averages,legend=false)
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"public_services_eu.png"))
    end

    
    let
        social_protection_code = lvl_1_codes[findfirst(==("Education"),lvl_1_names)]
        social_protection_subcategories = filter(expenditure_codes) do x
            codelist[x].parent == social_protection_code
        end

        shortened_sp = Dict("Secondary education" => "Secondary school",
            "Pre-primary and primary education" => "(Pre)primary school",
            "Education not definable by level" => "Other education",
            "Post-secondary non-tertiary education"=>"Post-secondary non-tertiary",
            "Subsidiary services to education" => "Subsidiary services")

        social_protection_subcategories_names = [codelist[x].name for x in social_protection_subcategories]
        social_protection_subcategories_names = [get(shortened_sp,x,x) for x in social_protection_subcategories_names]
        
        pie_values = map(social_protection_subcategories) do tx
            df_belgium[df_belgium[!,"EXPENDITURE"].==tx,"OBS_VALUE"][1]
        end
        sp = reverse(sortperm(pie_values))
        social_protection_subcategories = social_protection_subcategories[sp]
        social_protection_subcategories_names = social_protection_subcategories_names[sp]
        pie_values = pie_values[sp]


        
        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]
        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(social_protection_subcategories_names,pie_values,right_margin=50mm,legend=(1.1,0.8))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"education_belgium.png"))

        averages = map(social_protection_subcategories) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE==code
                @select i
                @collect DataFrame
            end)[!,"OBS_VALUE"])
        end

        tot = sum(averages)
        percentages = [sprintf1("%0.1f",x)*"%" for x in averages./tot*100]
        θ = (cumsum(averages) - averages/2) .* 360/sum(averages)
        scθ = sincosd.(θ)

        using Plots.Measures
        p = pie(social_protection_subcategories_names,averages,legend=false)
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black))
        end
        p

        savefig(joinpath(FIGURE_DIR,"education_eu.png"))
    end

end