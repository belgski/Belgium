cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.WISE.WDP,DSD_HSL@DF_HSL_CWB,1.1/...._T._T.?lastNObservations=1&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.WISE.WDP/DSD_HSL@DF_HSL_CWB/1.1?references=all",structure_file)
end

(DataFrame(CSV.File(data_file,stringtype=String)),parse_structure_xml(structure_file))