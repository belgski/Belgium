cur_dir = @__DIR__



function parse_sheet_to_df(sheet,tablestart)
    # only works for sheets that have a category and subcategory
    sheet_data = XLSX.getdata(sheet)
    title = sheet_data[1,1]

    names_row = sheet_data[tablestart,:]
    names_mask = (!).(ismissing.(names_row))

    country_names = names_row[names_mask]

    data = Dict("category" => [], "subcategory" => [], [n => [] for n in country_names]...)

    cur_category = ""
    # go in increments of 2 to skip the std error
    for row_ind in tablestart+1:2:size(sheet_data,1) 
        cur_category = ismissing(sheet_data[row_ind,1]) ? cur_category : sheet_data[row_ind,1]
        subcategory = sheet_data[row_ind,2]
        ismissing(subcategory) && break
        
        push!(data["category"],cur_category)
        push!(data["subcategory"],subcategory)
        
        for (name,val) in  zip(country_names,sheet_data[row_ind,names_mask])
            push!(data[name],val)
        end
    end

    return title,DataFrame(data)
end


data_file_1 = joinpath(cur_dir,"data1.csv")
data_file_2 = joinpath(cur_dir,"data2.csv")
if !isfile(data_file_1) || !isfile(data_file_2)
    zip_file = joinpath(cur_dir,"data.zip")
    if !isfile(zip_file)
        Downloads.download("https://www.ecb.europa.eu/home/pdf/research/hfcn/HFCS_Statistical_Tables_Wave_2021_July2023.zip",zip_file)
    end
    
    zarchive = ZipFile.Reader(zip_file)
    for file in zarchive.files
       
        open(joinpath(cur_dir,"unzipped.xlsx"),"w") do f
            write(f,read(file))
        end

        f = XLSX.readxlsx(joinpath(cur_dir,"unzipped.xlsx"))

        if !isfile(data_file_1)
            (table_name,df_main_tables) = parse_sheet_to_df(f[3],5)
            @assert "A. Main tables" == table_name
            CSV.write(data_file_1,df_main_tables)
        end

        if !isfile(data_file_2)
            (table_name,df_main_tables) = parse_sheet_to_df(f[5],4)
            @assert "Table A3 Net wealth medians - breakdowns" == table_name
            CSV.write(data_file_2,df_main_tables)
        end
    end
end

(data = (DataFrame(CSV.File(data_file_1,stringtype=String)),DataFrame(CSV.File(data_file_2,stringtype=String))), source = "ECB:HFCS_2021")