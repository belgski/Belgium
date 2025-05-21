let
    cur_dir = @__DIR__


    belgian_outline_shapefiles = joinpath(cur_dir,"outline_shapefiles")
    if !isdir(belgian_outline_shapefiles)
        belgian_outline_shapefiles_zip = joinpath(cur_dir,"be_shape.zip")
        if !isfile(belgian_outline_shapefiles_zip)
            Downloads.download("https://geowebservices.stanford.edu/geoserver/wfs?outputformat=SHAPE-ZIP&request=GetFeature&service=wfs&srsName=EPSG%3A4326&typeName=druid%3Ahs337qd4914&version=2.0.0",belgian_outline_shapefiles_zip)
        end

        mkdir(belgian_outline_shapefiles)
        zarchive = ZipFile.Reader(belgian_outline_shapefiles_zip)
        for file in zarchive.files

            out_file = joinpath(belgian_outline_shapefiles,"outline."*split(file.name,'.')[end])
            open(out_file,"w") do f
                write(f,read(file))
            end
        end
    end

    belgian_postal_shapefiles = joinpath(cur_dir,"postal_shapefiles")
    if !isdir(belgian_postal_shapefiles)
        belgian_postal_shapefiles_zip = joinpath(cur_dir,"be_postal.zip")
        if !isfile(belgian_postal_shapefiles_zip)
            Downloads.download("https://bgu.bpost.be/assets/9738c7c0-5255-11ea-8895-34e12d0f0423_x-shapefile_31370.zip",belgian_postal_shapefiles_zip)
        end

        mkdir(belgian_postal_shapefiles)
        zarchive = ZipFile.Reader(belgian_postal_shapefiles_zip)
        for file in zarchive.files

            out_file = joinpath(belgian_postal_shapefiles,"postal."*split(file.name,'.')[end])
            open(out_file,"w") do f
                write(f,read(file))
            end
        end
    end

    belgian_postal_names = joinpath(cur_dir,"data.csv")
    if !isfile(belgian_postal_names)
        belgian_website_data = joinpath(cur_dir,"zipcodes.html")
        if !isfile(belgian_website_data)
            Downloads.download("http://www.bpost2.be/zipcodes/files/zipcodes_num_nl_new.html",belgian_website_data)
        end
        
        data = Dict("postal" => [], "name" =>[])
        doc = read(belgian_website_data,LazyNode)
        
        for node in doc
            if tag(node) == "tr"
                cols = children(node)
                length(children(cols[1])) == 0 && continue
                length(children(cols[3])) == 0 && continue
                a = value(children(cols[1])[1])
                b = value(children(cols[2])[1])
                is_deelgemeente = value(children(cols[3])[1])
                hoofdgemeente = value(children(cols[4])[1])
                all([isdigit(d) for d in a]) || continue
                hoofdgemeente = replace(hoofdgemeente,"&" => "", "circ;" => "", "acute;" => "", "grave;" => "")
                push!(data["postal"],parse(Int,a))
                push!(data["name"],hoofdgemeente)
            end
        end
        CSV.write(belgian_postal_names,   DataFrame(data))
    end

    (joinpath(belgian_outline_shapefiles,"outline"),joinpath(belgian_postal_shapefiles,"postal"), DataFrame(CSV.File(belgian_postal_names,stringtype=String)))
end