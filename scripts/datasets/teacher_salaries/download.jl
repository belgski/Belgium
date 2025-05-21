cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.EDU.IMEP,DSD_EAG_SAL_TREND@DF_TCH_STA,/..XDC..ISCED11_0+ISCED11_3+ISCED11_2+ISCED11_02+ISCED11_34+ISCED11_24+ISCED11_1....TYP_EXP..V?startPeriod=2019&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.EDU.IMEP/DSD_EAG_SAL_TREND@DF_TCH_STA/?references=all",structure_file)
end

(DataFrame(CSV.File(data_file,stringtype=String)),parse_structure_xml(structure_file))