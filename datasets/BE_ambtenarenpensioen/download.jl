cur_dir = @__DIR__


data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
   #url = "https://www.pdos-sdpsp.fgov.be/nl/statistics/2022/income/income_rp_all_all_pure_$(TIME_PERIOD).htm"
   url = "https://www.pdos-sdpsp.fgov.be/nl/statistics/2022/income/income_rp_all_all_all_$(TIME_PERIOD).htm"
   data = readtable(url,class="stat-results")
   mat = vcat([hcat(d[1],d[end-1],d[end]) for d in data[1]]...)
   mat[1,1] = "Schijf"
   df = DataFrame(mat[2:end,:],mat[1,:])
    CSV.write(data_file, df)
end


DataFrame(CSV.File(data_file,stringtype=String))