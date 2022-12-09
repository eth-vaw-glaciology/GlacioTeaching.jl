using GlacioTeaching
using Test

@testset "Literate processing" begin
    GlacioTeaching.process_folder("input/", "output_sol/", make_outputs=:sol)
    @test hash(read("output_sol/test-literate.ipynb"))==0x6ae0c030a3f57c63
    rm(joinpath(@__DIR__,"output_sol"), recursive=true)
    GlacioTeaching.process_folder("input/", "output_assignment/", make_outputs=:assignment)
    @test hash(read("output_assignment/test-literate.ipynb"))==0x9232764bd864b451
    rm(joinpath(@__DIR__,"output_assignment"), recursive=true)
end
