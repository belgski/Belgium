cur_dir = @__DIR__


data_file = joinpath(cur_dir,"data.csv")
if !isfile(data_file)
    zip_file = joinpath(cur_dir,"data.zip")
    if !isfile(zip_file)
        Downloads.download("https://statbel.fgov.be/sites/default/files/files/opendata/immo/vastgoed_2010_9999.zip",zip_file)
    end

    zarchive = ZipFile.Reader(zip_file)
    for file in zarchive.files
        @assert !isfile(data_file) # will error if there are multiple txt fils in that zip, which there shouldn't be
        CSV.write(data_file,   DataFrame(CSV.File(file)))
    end
end


DataFrame(CSV.File(data_file,stringtype=String))