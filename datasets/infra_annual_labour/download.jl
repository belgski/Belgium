cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_LFS@DF_IALFS_INDIC,1.0/....Y._T...A?startPeriod=2012&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.SDD.TPS/DSD_LFS@DF_IALFS_INDIC/1.0?references=all",structure_file)
end


parse_oecd_dataset(data_file,structure_file)