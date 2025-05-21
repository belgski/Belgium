let
    df = datasets["government_spending_by_function"]

    df_eu = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @select {REF_AREA = i.REF_AREA.name, i.OBS_VALUE, i.UNIT_MULT, i.EXPENDITURE}
        @collect DataFrame
    end
    df_eu[!,"OBS_VALUE"] .*=10 .^(df_eu[!,"UNIT_MULT"].-6)

    df_belgium = @from i in df_eu begin
        @where i.REF_AREA == TARGET_NAME
        @select i
        @collect DataFrame
    end
    

    let
        parent_level = "Total"
        lvl_1_names = [x.name for x in df_belgium.EXPENDITURE if x.parent == parent_level]

        shortened = Dict("Public order and safety"=> "Order/safety",
                    "Recreation, culture and religion" => "Recreation/culture", #religion is a piece of culture no?
                    "Housing and community amenities" => "Housing/community amenities")

        pie_values = map(lvl_1_names) do tx
            df_belgium.OBS_VALUE[findfirst(x->x.name == tx,df_belgium[!,"EXPENDITURE"])]
        end
        sp = reverse(sortperm(pie_values))
        lvl_1_names = lvl_1_names[sp]
        lvl_1_shortened_names = [get(shortened,x,x) for x in lvl_1_names]
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

        averages = map(lvl_1_names) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE.name == code

                #@join j in df_eu on i.REF_AREA equals j.REF_AREA
                #@where j.EXPENDITURE.name == parent_level


                #@select i.OBS_VALUE/j.OBS_VALUE
                @select i.OBS_VALUE
                @collect
            end))
        end

        pie_values = averages
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
        parent_level = "Social protection"
        lvl_1_names = [x.name for x in df_belgium.EXPENDITURE if x.parent == parent_level]

        shortened = Dict()

        pie_values = map(lvl_1_names) do tx
            df_belgium.OBS_VALUE[findfirst(x->x.name == tx,df_belgium[!,"EXPENDITURE"])]
        end
        sp = reverse(sortperm(pie_values))
        lvl_1_names = lvl_1_names[sp]
        lvl_1_shortened_names = [get(shortened,x,x) for x in lvl_1_names]
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

        savefig(joinpath(FIGURE_DIR,"social_protection_belgium.png"))

        averages = map(lvl_1_names) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE.name == code

                #@join j in df_eu on i.REF_AREA equals j.REF_AREA
                #@where j.EXPENDITURE.name == parent_level


                #@select i.OBS_VALUE/j.OBS_VALUE
                @select i.OBS_VALUE
                @collect
            end))
        end

        pie_values = averages
        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]


        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        p = pie(lvl_1_shortened_names,pie_values,legend=false)#,right_margin=40mm,legend=(1,0.5))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black,halign = :center))
        end
        p


        savefig(joinpath(FIGURE_DIR,"social_protection_eu.png"))
    end


    let
        parent_level = "General public services"
        lvl_1_names = [x.name for x in df_belgium.EXPENDITURE if x.parent == parent_level]

        shortened = Dict("R&D General public services"=> "R&D",
                    "Executive and legislative organs, financial and fiscal affairs, external affairs" => "Greedy government",
                    "Transfers of a general character between different levels of government" => "Intra-government transfers")

        pie_values = map(lvl_1_names) do tx
            df_belgium.OBS_VALUE[findfirst(x->x.name == tx,df_belgium[!,"EXPENDITURE"])]
        end
        sp = reverse(sortperm(pie_values))
        lvl_1_names = lvl_1_names[sp]
        lvl_1_shortened_names = [get(shortened,x,x) for x in lvl_1_names]
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

        savefig(joinpath(FIGURE_DIR,"public_services_belgium.png"))

        averages = map(lvl_1_names) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE.name == code

                #@join j in df_eu on i.REF_AREA equals j.REF_AREA
                #@where j.EXPENDITURE.name == parent_level


                #@select i.OBS_VALUE/j.OBS_VALUE
                @select i.OBS_VALUE
                @collect
            end))
        end

        pie_values = averages
        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]


        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        p = pie(lvl_1_shortened_names,pie_values,legend=false)#,right_margin=40mm,legend=(1,0.5))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black,halign = :center))
        end
        p


        savefig(joinpath(FIGURE_DIR,"public_services_eu.png"))
    end

    
    let
        parent_level = "Education"
        lvl_1_names = [x.name for x in df_belgium.EXPENDITURE if x.parent == parent_level]

        shortened = Dict("Secondary education" => "Secondary school",
            "Pre-primary and primary education" => "(Pre)primary school",
            "Education not definable by level" => "Other education",
            "Post-secondary non-tertiary education"=>"Post-secondary non-tertiary",
            "Subsidiary services to education" => "Subsidiary services")

        pie_values = map(lvl_1_names) do tx
            df_belgium.OBS_VALUE[findfirst(x->x.name == tx,df_belgium[!,"EXPENDITURE"])]
        end
        sp = reverse(sortperm(pie_values))
        lvl_1_names = lvl_1_names[sp]
        lvl_1_shortened_names = [get(shortened,x,x) for x in lvl_1_names]
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

        savefig(joinpath(FIGURE_DIR,"education_belgium.png"))

        averages = map(lvl_1_names) do code
            mean((@from i in df_eu begin
                @where i.EXPENDITURE.name == code

                #@join j in df_eu on i.REF_AREA equals j.REF_AREA
                #@where j.EXPENDITURE.name == parent_level


                #@select i.OBS_VALUE/j.OBS_VALUE
                @select i.OBS_VALUE
                @collect
            end))
        end

        pie_values = averages
        tot = sum(pie_values)
        percentages = [sprintf1("%0.1f",x)*"%" for x in pie_values./tot*100]


        θ = (cumsum(pie_values) - pie_values/2) .* 360/sum(pie_values)
        scθ = sincosd.(θ)

        p = pie(lvl_1_shortened_names,pie_values,legend=false)#,right_margin=40mm,legend=(1,0.5))
        for (i,(s, sci)) in enumerate(zip(percentages, scθ))
            annotate!(sci[2]*0.6, sci[1]*0.6, Plots.text(s, 9, :black,halign = :center))
        end
        p


        savefig(joinpath(FIGURE_DIR,"education_eu.png"))
    end

end