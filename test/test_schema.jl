using Test
using JuliaPowerCase

@testset "Schema & @define_schema" begin
    # BusSchema column access
    @test colidx(BusSchema, Val(:I))    == 1
    @test colidx(BusSchema, Val(:TYPE))  == 2
    @test colidx(BusSchema, Val(:VM))    == 8
    @test colidx(BusSchema, Val(:VMAX))  == 12
    @test colidx(BusSchema, Val(:VMIN))  == 13
    @test colidx(BusSchema, Val(:OMEGA)) == 21
    @test ncols(BusSchema) == 21

    # GenSchema (INDEX is now column 1)
    @test colidx(GenSchema, Val(:INDEX))   == 1
    @test colidx(GenSchema, Val(:GEN_BUS)) == 2
    @test colidx(GenSchema, Val(:PG))      == 3
    @test colidx(GenSchema, Val(:PMAX))    == 10
    @test ncols(GenSchema) == 48  # 44 + 4 sequence network params (R1, X1, R2, X2)

    # BranchSchema (INDEX is now column 1)
    @test colidx(BranchSchema, Val(:INDEX))  == 1
    @test colidx(BranchSchema, Val(:F_BUS))  == 2
    @test colidx(BranchSchema, Val(:T_BUS))  == 3
    @test colidx(BranchSchema, Val(:STATUS)) == 12
    @test ncols(BranchSchema) == 38

    # Column names
    names = colnames(BusSchema)
    @test length(names) == 21
    @test names[1] == :I
    @test names[8] == :VM
    @test names[21] == :OMEGA

    # DCBusSchema
    @test ncols(DCBusSchema) >= 6
end
