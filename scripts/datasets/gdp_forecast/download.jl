cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/archive/rest/data/OECD,DF_EO114_LTB,/.GDP..A?startPeriod=2020&endPeriod=2060&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/archive/rest/dataflow/OECD/DF_EO114_LTB/?references=all",structure_file)
end

(DataFrame(CSV.File(data_file,stringtype=String)),parse_structure_xml(structure_file))