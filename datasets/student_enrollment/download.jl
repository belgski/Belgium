cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.EDU.IMEP,DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_RAW_AGE,1.0/AUT+BEL+CAN+CHL+COL+CRI+CZE+DNK+EST+FIN+FRA+DEU+GRC+HUN+ISL+IRL+ISR+ITA+JPN+KOR+LVA+LTU+LUX+MEX+NLD+NZL+NOR+POL+PRT+SVK+SVN+ESP+SWE+CHE+TUR+GBR+USA+BRA+BGR+HRV+PER+ROU+AUS.ISCED11_0+ISCED11_1+ISCED11_2+ISCED11_3+ISCED11_35+ISCED11_4+ISCED11_5+ISCED11_6+ISCED11_7+ISCED11_8.ENRL.....A...._T.._T._T?startPeriod=2013&endPeriod=2022&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.EDU.IMEP/DSD_EAG_UOE_NON_FIN_STUD@DF_UOE_NF_RAW_AGE/1.0?references=all",structure_file)
end

parse_oecd_dataset(data_file,structure_file)