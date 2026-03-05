using Test
using JuliaPowerCase

@testset "ComponentMatrix" begin
    # Create from row count
    mat = ComponentMatrix{BusSchema, Float64}(5)
    @test nrows(mat) == 5
    @test size(rawdata(mat)) == (5, ncols(BusSchema))
    @test schema_type(mat) == BusSchema

    # Integer indexing
    mat[1, 1] = 42.0
    @test mat[1, 1] == 42.0

    # Symbol indexing
    mat[1, :VM] = 1.05
    @test mat[1, :VM] == 1.05
    @test mat[1, colidx(BusSchema, Val(:VM))] == 1.05

    # Set via symbol
    mat[2, :I] = 7.0
    @test mat[2, :I] == 7.0

    # Multi-symbol access
    mat[3, :I]    = 3.0
    mat[3, :TYPE] = 1.0
    mat[3, :VM]   = 0.98
    vals = mat[3, (:I, :TYPE, :VM)]
    @test vals == (3.0, 1.0, 0.98)

    # Construct from matrix data
    data = zeros(2, ncols(GenSchema))
    data[1, 1] = 1.0  # INDEX
    data[1, 2] = 1.0  # GEN_BUS
    data[1, 3] = 50.0 # PG
    gmat = ComponentMatrix{GenSchema, Float64}(data)
    @test gmat[1, :INDEX] == 1.0
    @test gmat[1, :GEN_BUS] == 1.0
    @test gmat[1, :PG] == 50.0
    @test nrows(gmat) == 2

    # Row slicing (INDEX is column 1, F_BUS is column 2, T_BUS is column 3)
    bmat = ComponentMatrix{BranchSchema, Float64}(3)
    bmat[1, :INDEX] = 1.0
    bmat[1, :F_BUS] = 1.0
    bmat[1, :T_BUS] = 2.0
    bmat[2, :INDEX] = 2.0
    bmat[2, :F_BUS] = 2.0
    bmat[2, :T_BUS] = 3.0
    @test bmat[1, :INDEX] == 1.0
    @test bmat[1, :F_BUS] == 1.0
    @test bmat[2, :T_BUS] == 3.0
end
