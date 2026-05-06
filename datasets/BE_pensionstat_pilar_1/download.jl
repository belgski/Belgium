cur_dir = @__DIR__


data_file = joinpath(cur_dir,"data.xlsx")
if !isfile(data_file)
    xlsx_file = joinpath(cur_dir,"data.xlsx")
    if !isfile(xlsx_file)
        Downloads.download("https://www.pensionstat.be/file/6103c41969844d308979992d7f84d51e59927e1e/eb7f0751cf6fbd1e0898a79e5a16bb777b12d8ea/data_$(TIME_PERIOD)_nl.xlsx",xlsx_file)
    end

end

xf = XLSX.readxlsx(data_file)
(data = DataFrame(XLSX.gettable(xf["Gepensioneerden"])), source = "pensionstat.be:pilar_1")