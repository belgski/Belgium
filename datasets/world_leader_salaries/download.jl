cur_dir = @__DIR__

(data = (DataFrame(CSV.File( joinpath(cur_dir,"salary_leader.csv"))),DataFrame(CSV.File( joinpath(cur_dir,"salary_parliament.csv")))), source = "politicalsalaries.com")