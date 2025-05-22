using HTTP, CSV ,DataFrames, Query, XML, Plots, Downloads, PythonCall, Countries, Formatting, GLM, PrettyTables, Statistics
using GeoInterface,Shapefile,ArchGDAL
using Plots.Measures

cd(@__DIR__)
include("utils.jl")

# Important
# Datasets are downloaded and stored, but they are also dependent on global variables defined here. 
# If you change any of these variables, also remove all stored datasets before re-running the script.

const ROOT_DIR = @__DIR__
const FIGURE_DIR = joinpath(ROOT_DIR,"docs","assets")
const TIME_PERIOD = 2022

const EUROPEAN_AREA_NAMES = ["Slovenia", "Malta", "France", "Netherlands", "Estonia", "Slovakia", "Finland", "Austria", "Spain", "Italy", "Ireland", "Portugal", "Lithuania", "Cyprus", "Greece", "Germany", "Luxembourg", "Belgium", "Latvia"]
const TARGET_NAME = "Belgium"

# todo, change this to "Belgium" and adapt code
const COUNTRIES_DF = DataFrame(all_countries())


const TARGET = "BEL"



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


const datasets = Dict{String,Any}()
for f in readdir(joinpath(ROOT_DIR,"datasets"))
    f_full = joinpath(ROOT_DIR,"datasets",f)
    isdir(f_full) || continue
    
    datasets[f] = let
        include(joinpath(f_full,"download.jl"))
    end
end

open(joinpath(FIGURE_DIR,"compared_countries.txt"),"w") do f
    write(f,join(EUROPEAN_AREA_NAMES, ", ", " and "))
    write(f,".")
end

include("scripts/revenue/tax_breakdown.jl")
include("scripts/revenue/taxation_gdp_relationship.jl")
include("scripts/revenue/vat.jl")
include("scripts/revenue/net_vs_gross.jl")

include("scripts/expenditure/debt.jl")
include("scripts/expenditure/disability.jl")
include("scripts/expenditure/education.jl")
include("scripts/expenditure/expenditure_breakdown.jl")
include("scripts/expenditure/government.jl")
include("scripts/expenditure/old_age.jl")
include("scripts/expenditure/unemployment.jl")

include("scripts/nocat/well_being.jl")

include("scripts/fairness/house_costs.jl")
include("scripts/fairness/houses.jl")
include("scripts/fairness/wage_distribution.jl")

include("scripts/claims/immigration.jl")
include("scripts/claims/pensions.jl")
