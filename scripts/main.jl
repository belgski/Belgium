using HTTP, CSV ,DataFrames, Query, XML, Plots, Downloads, PythonCall, Countries, Formatting, GLM, PrettyTables, Statistics
using GeoInterface,Shapefile,ArchGDAL
using Plots.Measures

# Important
# Datasets are downloaded and stored, but they are also dependent on global variables defined here. 
# If you change any of these variables, also remove all stored datasets before re-running the script.

const ROOT_DIR = @__DIR__
const FIGURE_DIR = joinpath(ROOT_DIR,"..","docs","assets")
const TIME_PERIOD = 2022

const EUROPEAN_AREA_NAMES = ["Slovenia", "Malta", "France", "Netherlands", "Estonia", "Slovakia", "Finland", "Austria", "Spain", "Italy", "Ireland", "Portugal", "Lithuania", "Cyprus", "Greece", "Germany", "Luxembourg", "Belgium", "Latvia"]

# todo, change this to "Belgium" and adapt code
const TARGET = "BEL"
const TARGET_NAME = "Belgium"


const COUNTRIES_DF = DataFrame(all_countries())

function alpha2_to_eu(alpha2)
    # you will not believe it, but the european union does not use the official iso-2 codes
    if alpha2 == "GR"
        return "EL"
    elseif alpha2 == "GB"
        return "UK"
    else
        return alpha2
    end
end

# bit of a misnomer, maps iso_3 (used by oecd) => country name
const EUROPEAN_AREA_CODE_NAME = @from i in COUNTRIES_DF begin
    @where i.name in EUROPEAN_AREA_NAMES
    @select i.alpha3 => i.name
    @collect Dict
end

# maps iso_2 (used by eurostat) => country name
const EUROPEAN_AREA_ISO_NAME = @from i in COUNTRIES_DF begin
    @where i.name in EUROPEAN_AREA_NAMES
    @select alpha2_to_eu(i.alpha2) => i.name
    @collect Dict
end

# unsorted
const EUROPEAN_AREA_CODES = collect(keys(EUROPEAN_AREA_CODE_NAME))
const EUROPEAN_AREA_ISOS = collect(keys(EUROPEAN_AREA_ISO_NAME))

const TARGET_ISO = findfirst(==(TARGET_NAME),EUROPEAN_AREA_ISO_NAME)

function parse_codelist(doc)
    codelist = Dict()

    for node in doc
        if node.tag == "structure:Code"
            common_name = ""
            parent = nothing
            for a in children(node)
                if a.tag == "common:Name" && a.attributes["xml:lang"] == "en"   
                    common_name = XML.unescape(value(children(a)[1]))
                end

                if a.tag == "structure:Parent"
                    parent = children(a)[1].attributes["id"]
                end
            end

            codelist[node.attributes["id"]] = NamedTuple((:name => common_name, :parent => parent))
        end
    end

    return codelist
end
function parse_structure_xml(filename)
    doc = read(filename,LazyNode)

    # let's get a list of all structure:code's
    codelists = Dict()

    for node in doc
        if node.tag == "structure:Codelist"
            codelist_name = node.attributes["id"]
            codelists[codelist_name] = parse_codelist(children(node))
        end
    end

    return codelists
end

const datasets = Dict{String,Any}()
for f in readdir("datasets")
    f_full = joinpath("datasets",f)
    isdir(f_full) || continue
    
    datasets[f] = let
        include(joinpath(f_full,"download.jl"))
    end
end

open(joinpath(FIGURE_DIR,"compared_countries.txt"),"w") do f
    write(f,join(EUROPEAN_AREA_NAMES, ", ", " and "))
    write(f,".")
end

for f in readdir("revenue")
    let
        include(joinpath("revenue",f))
    end
end

for f in readdir("expenditure")
    let
        include(joinpath("expenditure",f))
    end
end

for f in readdir("nocat")
    let
        include(joinpath("nocat",f))
    end
end

for f in readdir("fairness")
    let
        include(joinpath("fairness",f))
    end
end

for f in readdir("claims")
    let
        include(joinpath("claims",f))
    end
end

