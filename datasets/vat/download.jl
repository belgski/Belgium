let
    cur_dir = @__DIR__


    data_file = joinpath(cur_dir,"data.csv")
    if !isfile(data_file)
            
        zeep = pyimport("zeep")
        client = zeep.Client("https://ec.europa.eu/taxation_customs/tedb/ws/VatRetrievalService.wsdl")

        data_dict = Dict("ISO" => [], "CN" => [], "Rate" => [])

        for cur_iso in EUROPEAN_AREA_ISOS
            retval = client.service.retrieveVatRates(memberStates = cur_iso, from = "$(TIME_PERIOD)-06-15", to = "$(TIME_PERIOD)-06-15")

            for res in retval.vatRateResults
                
                if pyconvert(String,res.rate.type) == "DEFAULT"
                    push!(data_dict["ISO"],cur_iso)
                    push!(data_dict["CN"],"")
                    push!(data_dict["Rate"],pyconvert(Float64,res.rate.value))
                end

                isnothing(pyconvert(Any,res.cnCodes)) && continue
                for code in res.cnCodes.code
                    push!(data_dict["ISO"],cur_iso)
                    push!(data_dict["CN"],replace(pyconvert(String,code.value), " "=>""))
                    push!(data_dict["Rate"],pyconvert(Float64,res.rate.value))
                end
                
            end
            
        end

        CSV.write(data_file,  DataFrame(data_dict))
    end

    structure_file = joinpath(cur_dir,"HS.csv")
    if !isfile(structure_file)
        Downloads.download("https://raw.githubusercontent.com/datasets/harmonized-system/refs/heads/main/data/harmonized-system.csv",structure_file)
    end
    DataFrame(CSV.File(data_file; types = Dict(:CN => String), missingstring=nothing)), DataFrame(CSV.File(structure_file; types = Dict(:hscode => String)))
end