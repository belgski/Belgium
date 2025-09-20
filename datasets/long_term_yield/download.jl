cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.SDD.STES,DSD_STES@DF_FINMARK,4.0/.A.IRLT.PA.....?dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.SDD.STES/DSD_STES@DF_FINMARK/4.0?references=all",structure_file)
end


parse_oecd_dataset(data_file,structure_file)