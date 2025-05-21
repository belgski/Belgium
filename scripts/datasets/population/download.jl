cur_dir = @__DIR__

data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/data/OECD.ELS.SAE,DSD_POPULATION@DF_POP_HIST,/AUS+AUT+CAN+CHL+COL+CRI+CZE+DNK+EST+FIN+FRA+DEU+GRC+HUN+ISL+IRL+ISR+ITA+JPN+KOR+LVA+LTU+LUX+MEX+NLD+NZL+NOR+POL+PRT+SVK+SVN+ESP+SWE+CHE+TUR+GBR+USA+ARG+BRA+BGR+CHN+HRV+CYP+IND+IDN+MLT+ROU+RUS+SAU+SGP+ZAF+BEL..PS._T._T+Y_LE4+Y5T9+Y10T14+Y15T19+Y15T64+Y_LT20+Y20T24+Y20T64+Y25T29+Y30T34+Y35T39+Y40T44+Y45T49+Y50T54+Y_GE50+Y55T59+Y60T64+Y65T69+Y_GE65+Y70T74+Y75T79+Y80T84+Y_GE85.?startPeriod=2010&endPeriod=2022&dimensionAtObservation=AllDimensions&format=csv",data_file)
end

structure_file = joinpath(cur_dir,"structure.xml")
if !isfile(structure_file)
    Downloads.download("https://sdmx.oecd.org/public/rest/dataflow/OECD.ELS.SAE/DSD_POPULATION@DF_POP_HIST/?references=all",structure_file)
end

(DataFrame(CSV.File(data_file,stringtype=String)),parse_structure_xml(structure_file))