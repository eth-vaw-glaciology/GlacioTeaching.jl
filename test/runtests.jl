using GlacioTeaching
using Test

@testset "Literate processing" begin

    # ipynb
    GlacioTeaching.process_folder("input/", "output_sol/", make_outputs=:sol)
    v"1.8"<VERSION<v"1.9" && @test hash(read("output_sol/test-literate.ipynb"))==0x6ae0c030a3f57c63
    rm(joinpath(@__DIR__,"output_sol"), recursive=true)
    GlacioTeaching.process_folder("input/", "output_assignment/", make_outputs=:assignment)
    v"1.8"<VERSION<v"1.9" && @test hash(read("output_assignment/test-literate.ipynb"))==0x9232764bd864b451
    rm(joinpath(@__DIR__,"output_assignment"), recursive=true)

    # md
    GlacioTeaching.process_folder("input/", "output_sol/", make_outputs=:sol, make_ipynb=false, make_md=true)
    @test hash(read("output_sol/test-literate.md"))==0x684e1f2ec590ddd5
    rm(joinpath(@__DIR__,"output_sol"), recursive=true)
    GlacioTeaching.process_folder("input/", "output_assignment/", make_outputs=:assignment, make_ipynb=false, make_md=true)
    @test hash(read("output_assignment/test-literate.md"))==0x6932dfdfa3b1542a
    rm(joinpath(@__DIR__,"output_assignment"), recursive=true)

end
