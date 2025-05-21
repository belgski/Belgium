be_trade_dataset =  datasets["BE_trade"]

# import = 1
# export = 2

df = @from i in be_trade_dataset begin
    @where !isnan(getfield(i,Symbol("$TIME_PERIOD")))
    @where i.product != "TOTAL"
    @where i.flow == 1
    @select {CN = i.product, AMOUNT =getfield(i,Symbol("$TIME_PERIOD"))}
    @collect DataFrame
end

cnc = df.CN

# go level by level through the dataframe, avoiding double counting of assets
for N in [8,6,4]
    for (ic,c) in enumerate(cnc)
        length(c) == N || continue

        parents = findall(cnc) do pc
            startswith(c,pc) && length(pc)<N
        end

        for parent in parents
            df[parent,:].AMOUNT -= df[ic,:].AMOUNT
        end
    end
end

# remove 0's
df = @from i in df begin
    @where i.AMOUNT>1e-5
    @select i
    @collect DataFrame
end

# given the import-by-category in "df", we can now go through the VAT database and evaluate the expected tax revenue had that order flow taken place in that country
(vat_df,cn_codes) = datasets["vat"]

# whenever possible, group revenue by the lvl-4 hscode
grouping_level = 2

possible_groups = filter(x->length(x) == grouping_level,cn_codes.hscode)
push!(possible_groups,"Undefined")

out_data = Dict("ISO" => [], "REV" => [], "GROUP" => [])



for ISO in EUROPEAN_AREA_ISOS

    vat_df_cur = @from i in vat_df begin
        @where i.ISO == ISO
        @select i
        @collect DataFrame
    end

    revenue_dict = Dict(p => 0.0 for p in possible_groups)

    # for every entry, look up the vat tax code    
    for row in eachrow(df)

        hits = findall(vat_df_cur.CN) do c
            startswith(row.CN,c)
        end

        most_applicable_entry = sortperm(vat_df_cur.CN)[end]
        cur_rev = vat_df_cur[most_applicable_entry,:].Rate/100 * row.AMOUNT

        if length(row.CN) < grouping_level || !(haskey(revenue_dict,row.CN[1:grouping_level]))
            revenue_dict["Undefined"] += cur_rev
        else
            revenue_dict[row.CN[1:grouping_level]] += cur_rev
        end
    end

    for (g,v) in revenue_dict
        push!(out_data["ISO"],ISO)
        push!(out_data["REV"],v/1000000000)
        push!(out_data["GROUP"],g)
    end
end

out_df = DataFrame(out_data)

out_total = @from i in out_df begin
    @group i by i.ISO into g
    @select {ISO = key(g), REV =sum(g.REV)[]}
    @collect DataFrame
end
 
sp = sortperm(out_total.REV)
ref_areas = out_total.ISO[sp]
ref_area_labels = [EUROPEAN_AREA_ISO_NAME[c] for c in ref_areas]
palette = Plots.palette(:tab10);
colors = [a == TARGET_ISO ? palette[2] : palette[1] for a in ref_areas]
bar(ref_area_labels, out_total.REV[sp], legend=false, yaxis="Expected VAT revenue (Billion euro)", xaxis="Country policy", color=colors,  xrotation=35, xticks = (1:length(ref_area_labels),ref_area_labels),bottommargin=5mm)

(df, codelists) = datasets["government_taxation_revenue"]

codelist = codelists["CL_STANDARD_REVENUE"]
total_code = findfirst(x->x.name=="Value added taxes (VAT)",codelist)

df_total_vat = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="XDC"
    @where i.STANDARD_REVENUE == total_code
    @where i.REF_AREA == TARGET
    @select i
    @collect DataFrame
end
df_total_vat[!,"OBS_VALUE"] .*=10 .^(df_total_vat[!,"UNIT_MULT"].-9)
actual_belgain_vat_rev = df_total_vat.OBS_VALUE

hline!(actual_belgain_vat_rev)
savefig(joinpath(FIGURE_DIR,"vat_policy.png"))

# find out how many billions we would have made by following the dutch policy
# contrast that to revenue made through 
# - Income/Profit/Capital gains
bi = findfirst(==(TARGET_ISO),out_total.ISO)
ti = sp[Int(round(length(sp)/2))]
iso_reasonable_country_policy = out_total.ISO[ti]
revenue_increase = out_total.REV[ti]-out_total.REV[bi]
# in billions
codelist = codelists["CL_STANDARD_REVENUE"]
income_code = findfirst(x->x.name=="Taxes on income, profits and capital gains of individuals and corporations",codelist)
df_total_income = @from i in df begin
    @where i.TIME_PERIOD==TIME_PERIOD
    @where i.UNIT_MEASURE=="XDC"
    @where i.STANDARD_REVENUE == total_code
    @where i.REF_AREA == TARGET
    @select i
    @collect DataFrame
end
df_total_income[!,"OBS_VALUE"] .*=10 .^(df_total_income[!,"UNIT_MULT"].-9)

rev_incr_tr = sprintf1("%0.1f",revenue_increase)
rev_incr_propto_tr = sprintf1("%0.1f",revenue_increase/df_total_income.OBS_VALUE[1] *100)
optional_the = iso_reasonable_country_policy == "NL" ? "the" : ""
open(joinpath(FIGURE_DIR,"vat_policy_change.txt"),"w") do f
    write(f,"Had $(TARGET_NAME) changed to the policy of $(optional_the) $(EUROPEAN_AREA_ISO_NAME[iso_reasonable_country_policy]), it would have made $(rev_incr_tr) Billion Euro more through VAT. That revenue increase is $(rev_incr_propto_tr)% of revenue through income, profits and capital gains of individuals and corporations.")
end

# find out which categories would be most affected
rev_diff = @from i in out_df begin
    @where i.ISO == TARGET_ISO
    @join j in out_df on i.GROUP equals j.GROUP
    @where j.ISO == iso_reasonable_country_policy
    @select {i.GROUP, REV_DIFF = (j.REV - i.REV)[]}
    @collect DataFrame
end



print_df_data = Dict("Category" => [], "Extra revenue (Billion Euro)" => [])
for s in sortperm(rev_diff.REV_DIFF)[end:-1:end-5]
    push!(print_df_data["Category"],cn_codes.description[findfirst(==(rev_diff.GROUP[s]),cn_codes.hscode)])
    push!(print_df_data[ "Extra revenue (Billion Euro)" ],sprintf1("%0.1f",rev_diff.REV_DIFF[s]))
end


open(joinpath(FIGURE_DIR,"vat_biggest_changes.txt"),"w") do f
    pretty_table(f,DataFrame(print_df_data), backend = Val(:markdown))
end
