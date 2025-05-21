cur_dir = @__DIR__


data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    eurostat = pyimport("eurostat")
    #filters = Dict("freq" => "A", "time" => "$TIME_PERIOD", "indicators" => "VALUE_IN_EUROS","partner"=> "WORLD","reporter" => TARGET_ISO)
    data = eurostat.get_data_df("ILC_DI01")#,filter_pars = pydict(filters))
    
    CSV.write(data_file,  DataFrame(pyconvert(Any,data)))
end

rename(DataFrame(CSV.File(data_file)),"geo\\TIME_PERIOD"=>"geo")