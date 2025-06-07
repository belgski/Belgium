(summary_df, breakdown_df) = datasets["household_wealth"]

summary_df = @from i in summary_df begin
    @where i.category == "All"
    @where i.subcategory == "DN3001 Net wealth"
    @select i
    @collect DataFrame
end

breakdown_df = @from i in breakdown_df begin
    @where i.category == "Age of RP"

    @select i
    @collect DataFrame
end

subcats = breakdown_df.subcategory
wealth = breakdown_df[!,TARGET_ISO]

bar(subcats,wealth,legend = false,yaxis = "Net wealth (thousand Euro)")
savefig(joinpath(FIGURE_DIR,"wealth_by_age.png"))

# I want to know the average wealth of someone of working age (15-64) compared to someone older