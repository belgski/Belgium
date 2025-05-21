cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.CTP.TPS,DSD_TAX_WAGES_COMP@DF_TW_COMP,/.GEBT+NIAT+GLCBT..C_C2+S_C0...A?startPeriod=2015&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.CTP.TPS/DSD_TAX_WAGES_COMP@DF_TW_COMP/?references=all",structure_file)
end

parse_oecd_dataset(data_file,structure_file)