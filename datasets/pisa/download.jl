cur_dir = @__DIR__

data_file = joinpath(cur_dir,"student_$(TIME_PERIOD).rds")
if !isfile(data_file)
    Downloads.download("https://github.com/kevinwang09/learningtower/raw/refs/heads/master/student_full_data/student_$(TIME_PERIOD).rds",data_file)
end

(data = load(data_file, convert=true), source = "GITHUB:learningtower")