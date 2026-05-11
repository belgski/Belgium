let
    cur_dir = @__DIR__


    data_file = joinpath(cur_dir,"data.csv")
    if !isfile(data_file)
        token = get(ENV,"APIFY_TOKEN","")
        raw_data = Dict{String,Vector{Float64}}()
        raw_data["Gross"] = collect(30000:10000:150000)

        for (index,grossIncome) in enumerate(raw_data["Gross"])

            qpoint = Dict(
                "employmentType" => "employed",
                "filingStatus" => "single",
                "grossIncome"=> grossIncome,
                "includeLocalTax"=> true
            )


            resp = HTTP.post("https://api.apify.com/v2/acts/trovevault~eu-salary-calculator/run-sync-get-dataset-items?token=$token", Dict("Content-Type" => "application/json"), JSON3.write(qpoint))
            blub = JSON3.read(resp.body,Vector{Dict})

            for l in blub
                countryCode = l["country"] * "_net"
                if !(countryCode in keys(raw_data))
                    raw_data[countryCode] = zeros(length(raw_data["Gross"]))
                end

                raw_data[countryCode][index] = l["netAnnual"]

                countryCode = l["country"] * "_employer"
                if !(countryCode in keys(raw_data))
                    raw_data[countryCode] = zeros(length(raw_data["Gross"]))
                end

                raw_data[countryCode][index] = l["totalEmployerCost"]
            end
        end

        

        
        CSV.write(data_file,  DataFrame(raw_data))
    end

    (data = DataFrame(CSV.File(data_file)), source = "APIFY:trovevault~eu-salary-calculator")
end