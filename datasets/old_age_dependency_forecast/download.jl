cur_dir = @__DIR__


data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    eurostat = pyimport("eurostat")
    data = eurostat.get_data_df("tps00200")
    
    CSV.write(data_file,  DataFrame(pyconvert(Any,data)))
end

(data = rename(DataFrame(CSV.File(data_file)),"geo\\TIME_PERIOD"=>"geo"), source = "EUROSTAT:tps00200")
