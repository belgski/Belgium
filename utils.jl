

function parse_oecd_structure(doc)
    
    structure_codes = Dict()
    start_depth = depth(doc)
    for node in doc
        depth(node) <= start_depth && break
        if node.tag == "structure:Dimension"
            isnothing(node.attributes) && continue
            col_name = node.attributes["id"]
            codelist = nothing
            node_depth = depth(node)
            for c in node
                depth(c) <= node_depth && break
            
                if c.tag == "Ref" && c.attributes["class"] == "Codelist"
                    @assert isnothing(codelist)
                    codelist = c.attributes["id"]
                end
            end

            if !isnothing(codelist)
                structure_codes[col_name] = codelist
            end
        end

        
    end
    return structure_codes
end

function parse_oecd_dataflow(doc)
    #<Ref id="DSD_POPULATION" version="1.0" agencyID="OECD.ELS.SAE" package="datastructure" class="DataStructure" />
    start_depth = depth(doc)
    for node in doc
        depth(node) <= start_depth && break

        if node.tag == "Ref" && node.attributes["class"] == "DataStructure"
            return "$(node.attributes["agencyID"]):$(node.attributes["id"])($(node.attributes["version"]))"
        end
    end
end


function parse_oecd_codelist(doc)
    codelist = Dict()

    for node in doc
        if node.tag == "structure:Code"
            common_name = ""
            parent = ""
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
function parse_oecd_dataset(csv_file, structure_file)
    df = DataFrame(CSV.File(csv_file,stringtype=String))
    doc = read(structure_file,LazyNode)

    # let's get a list of all structure:code's
    codelists = Dict()
    datastructures = Dict()
    dataflows = Dict()
    entered_dataflows = Inf
    for node in doc
        if node.tag == "structure:Codelist"
            codelist_name = node.attributes["id"]
            codelists[codelist_name] = parse_oecd_codelist(children(node))
        end

        #       <structure:DataStructure id="DSD_POPULATION" agencyID="OECD.ELS.SAE" version="1.0" isFinal="true">
        if node.tag == "structure:DataStructure"
            datastructure_name = node.attributes["id"]
            datastructure_agency = node.attributes["agencyID"]
            datastructure_version = node.attributes["version"]
            datastructures["$datastructure_agency:$datastructure_name($datastructure_version)"] = parse_oecd_structure(node)
        end

        #       <structure:Dataflow id="DSD_POPULATION@DF_POP_HIST" agencyID="OECD.ELS.SAE" version="1.0" isFinal="true">
        if depth(node) <= entered_dataflows
            entered_dataflows = Inf
        end
        if node.tag == "structure:Dataflows"
            entered_dataflows = depth(node)
        end
       

        if node.tag == "structure:Dataflow" && depth(node) > entered_dataflows
            datastructure_name = node.attributes["id"]
            datastructure_agency = node.attributes["agencyID"]
            datastructure_version = node.attributes["version"]

            dataflows["$datastructure_agency:$datastructure_name($datastructure_version)"] = parse_oecd_dataflow(node)
        end
    end

    

    @assert names(df)[1] == "DATAFLOW"
    @assert length(unique(df.DATAFLOW)) == 1
    structure = datastructures[dataflows[df.DATAFLOW[1]]]
    for (i,name) in enumerate(names(df))
        haskey(structure,name) || continue
        cl = codelists[structure[name]]
        
        df[!,name] = [NamedTuple((:name => cl[x].name, :parent => (cl[x].parent == "" ? "" : cl[cl[x].parent].name))) for x in df[!,name]]
    end
    
    return df
end


