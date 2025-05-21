cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_LFS@DF_IALFS_INDIC,1.0/AUS+AUT+BEL+CAN+CHL+COL+CRI+CZE+DNK+EST+FIN+FRA+DEU+GRC+HUN+ISL+IRL+ISR+ITA+JPN+KOR+LVA+LTU+LUX+MEX+NLD+NZL+NOR+POL+PRT+SVK+SVN+ESP+SWE+CHE+TUR+GBR+USA+BRA+BGR+HRV+IDN+RUS+ZAF.WAP+LF+LF_WAP+EMP_WAP+UNE_M+UNE_LF+UNE_LF_M+UNE_ST+UNE_LT+OLF_WAP+OLF+UNE+EMP...Y._T.Y_GE15..A?startPeriod=2012&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.SDD.TPS/DSD_LFS@DF_IALFS_INDIC/1.0?references=all",structure_file)
end

(DataFrame(CSV.File(data_file,stringtype=String)),parse_structure_xml(structure_file))