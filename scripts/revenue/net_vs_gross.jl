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

    histogram(joined.NET_INCOME ./joined.GROSS_LABOUR .*100 ,xaxis="(net income)/(gross labour cost) %",yaxis="# of countries",bins = 40:2:70,alpha=0.2,label="average wage")
    belgium_row = joined[joined[!,"REF_AREA"] .== TARGET_NAME,:]

    vline!([belgium_row[1,"NET_INCOME"]/belgium_row[1,"GROSS_LABOUR"] * 100],color=:blue,label=false)

    df_gross_labour = @from i in df begin
        @where i.MEASURE.name == "Gross labour costs before taxes"
        @where i.INCOME_PRINCIPAL.name =="167% of average wage"
        @select {REF_AREA = i.REF_AREA.name ,GROSS_LABOUR = i.OBS_VALUE}
        @collect DataFrame
    end

    df_net_income = @from i in df begin
        @where i.MEASURE.name == "Net income after taxes"
        @where i.INCOME_PRINCIPAL.name =="167% of average wage"
        @select {REF_AREA = i.REF_AREA.name ,NET_INCOME = i.OBS_VALUE}
        @collect DataFrame
    end


    joined = innerjoin(df_gross_labour,df_net_income,on = "REF_AREA",makeunique=true)

    histogram!(joined.NET_INCOME ./joined.GROSS_LABOUR .*100 ,bins = 40:2:70,alpha=0.2,label="high wage")
    belgium_row = joined[joined[!,"REF_AREA"] .== TARGET_NAME,:]

    vline!([belgium_row[1,"NET_INCOME"]/belgium_row[1,"GROSS_LABOUR"] * 100],color=:green,label=false)
    savefig(joinpath(FIGURE_DIR,"net_income_vs_gross_labour.png"))
end