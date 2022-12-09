using GlacioTeaching
using Test

# note the file-hash testing is too fragile...
@testset "To Jupyter" begin
    # ipynb
    GlacioTeaching.process_folder("input/", "output_sol/", make_outputs=:sol)
    @test isfile("output_sol/test-literate.ipynb")
    #v"1.8"<VERSION<v"1.9" && @test hash(read("output_sol/test-literate.ipynb"))==0x6ae0c030a3f57c63
    rm(joinpath(@__DIR__,"output_sol"), recursive=true)
    GlacioTeaching.process_folder("input/", "output_assignment/", make_outputs=:assignment)
    @test isfile("output_assignment/test-literate.ipynb")
    #v"1.8"<VERSION<v"1.9" && @test hash(read("output_assignment/test-literate.ipynb"))==0x9232764bd864b451
    rm(joinpath(@__DIR__,"output_assignment"), recursive=true)
end

@testset "To Markdown" begin
    # md
    GlacioTeaching.process_folder("input/", "output_sol/", :md, make_outputs=:sol)
    #@test hash(read("output_sol/test-literate.md"))==0x684e1f2ec590ddd5
    @test isfile("output_sol/test-literate.md")
    rm(joinpath(@__DIR__,"output_sol"), recursive=true)
    GlacioTeaching.process_folder("input/", "output_assignment/", :md, make_outputs=:assignment)
    # @test hash(read("output_assignment/test-literate.md"))==0x6932dfdfa3b1542a
    @test isfile("output_assignment/test-literate.md")
    rm(joinpath(@__DIR__,"output_assignment"), recursive=true)
end
