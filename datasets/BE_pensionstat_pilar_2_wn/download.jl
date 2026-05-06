cur_dir = @__DIR__


data_file = joinpath(cur_dir,"data.xlsx")
if !isfile(data_file)
    xlsx_file = joinpath(cur_dir,"data.xlsx")
    if !isfile(xlsx_file)
        Downloads.download("https://www.pensionstat.be/file/6103c41969844d308979992d7f84d51e59927e1e/8e0d65ddd15fa06b2577bd919e9f1f730472a296/werknemers$(TIME_PERIOD)_nl.xlsx",xlsx_file)
    end

end

xf = XLSX.readxlsx(data_file)
(data = DataFrame(XLSX.gettable(xf["Reserves"])), source = "pensionstat.be:pilar_2_wn")