let
    df = datasets["wage_taxation"]

    df = @from i in df begin
        @where i.TIME_PERIOD==TIME_PERIOD
        @where i.UNIT_MEASURE.name =="US dollars, PPP converted"
        @where i.REF_AREA.name in EUROPEAN_AREA_NAMES
        @where i.HOUSEHOLD_TYPE.name == "Single person, no children"
        @select i
        @collect DataFrame
    end

    df_gross_labour = @from i in df begin
        @where i.MEASURE.name == "Gross labour costs before taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @select {REF_AREA = i.REF_AREA.name ,GROSS_LABOUR = i.OBS_VALUE}
        @collect DataFrame
    end


    df_net_income = @from i in df begin
        @where i.MEASURE.name == "Net income after taxes"
        @where i.INCOME_PRINCIPAL.name =="100% of average wage"
        @select {REF_AREA = i.REF_AREA.name ,NET_INCOME = i.OBS_VALUE}
        @collect DataFrame
    end


    joined = innerjoin(df_gross_labour,df_net_income,on = "REF_AREA",makeunique=true)

    sp = sortperm(joined.NET_INCOME ./joined.GROSS_LABOUR)
    ref_areas = joined.REF_AREA[sp]
    palette = Plots.palette(:tab10);
    colors = [a == TARGET_NAME ? palette[2] : palette[1] for a in ref_areas]
    bar(ref_areas, (joined.NET_INCOME ./joined.GROSS_LABOUR .*100)[sp], legend=false, yaxis="(net income)/(gross labour cost) %",color=colors,  xrotation=35, xticks = (1:length(ref_areas),ref_areas),bottommargin=5mm, title="Net income vs Gross labour cost" * get_source("wage_taxation"), titlefont=font(10,"Computer Modern"))


    savefig(joinpath(FIGURE_DIR,"net_income_vs_gross_labour.png"))
end

let 
    df = datasets["employee_costs"]
    
    
    pl = plot(title="Net income as % of Gross labour cost"*get_source("employee_costs"),
              xlabel="Gross Salary (EUR)", ylabel="Net/Gross labour cost (%)",
              titlefont=font(10,"Computer Modern"), legend=:outerright,
              xticks=([25000, 50000, 75000, 100000, 125000, 150000], ["25k", "50k", "75k", "100k", "125k", "150k"]))
    
    first_other = true
    for c in EUROPEAN_AREA_NAMES
        net_col_name = c*"_net"
        cost_col_name = c*"_employer"
        net_col_name in names(df) && cost_col_name in names(df) || continue
        plot!(pl, df[!,"Gross"], df[!,net_col_name]./df[!,cost_col_name] .* 100, label=first_other ? "Other EU" : "", color=:lightgray, lw=1)
        first_other = false
    end
    
    net_col_name = TARGET_NAME*"_net"
    cost_col_name = TARGET_NAME*"_employer"
    plot!(pl, df[!,"Gross"], df[!,net_col_name]./df[!,cost_col_name] .* 100,  label=TARGET_NAME, color=:blue, lw=3)
    
    savefig(joinpath(FIGURE_DIR,"net_vs_gross_employee_costs.png"))
end