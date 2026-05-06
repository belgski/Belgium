cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.CTP.TPS,DSD_REV_COMP_GLOBAL@DF_RSGLOBAL,2.1/..S13....A?startPeriod=2014&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.CTP.TPS/DSD_REV_COMP_GLOBAL@DF_RSGLOBAL/2.1?references=all",structure_file)
end

(data = parse_oecd_dataset(data_file,structure_file), source = "OECD:DSD_REV_COMP_GLOBAL@DF_RSGLOBAL")