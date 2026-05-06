let 
    df = datasets["BE_ambtenarenpensioen"]

    df_filtered = filter(row -> row.Schijf != "Totaal", df)
    # Maak de staafgrafiek aan.
    bar(
        df_filtered[!,"Schijf"],  # X-as: De inkomensschijven
        df_filtered[!,"Aantal pensioenen"],  # Y-as: Het aantal pensioenen
        title="Number of pensions per income" * get_source("BE_ambtenarenpensioen"),  # Titel van de grafiek
        xlabel="Income (€)",  # Label voor de X-as
        ylabel="Number of pensions (thousands)",  # Label voor de Y-as
        legend=false,  # Verberg de legende, aangezien die niet nodig is
        bar_width=0.7, # De breedte van de staven aanpassen
        xrotation=45,  # Draai de x-as labels 45 graden
        bottom_margin=15mm, # Vergroot de ondermarge zodat het label zichtbaar blijft
        titlefont=font(10,"Computer Modern")
    )
    savefig(joinpath(FIGURE_DIR,"ambtenarenpensioen.png"))
end