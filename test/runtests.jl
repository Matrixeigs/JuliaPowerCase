using Test
using JuliaPowerCase

@testset "JuliaPowerCase" begin
    include("test_schema.jl")
    include("test_component_matrix.jl")
    include("test_types.jl")
    include("test_containers.jl")
    include("test_conversion.jl")
    include("test_topology.jl")
    include("test_numbering.jl")
    include("test_cases.jl")
end
