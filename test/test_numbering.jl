using Test
using JuliaPowerCase

@testset "ext2int / int2ext" begin
    # IEEE 14-bus has contiguous numbering already, but let's test the round-trip
    jpc = case14()
    orig_bus_ids = [Int(jpc.bus[i, :I]) for i in 1:nbuses(jpc)]

    jpc_int, i2e = ext2int(jpc)
    @test length(i2e) == nbuses(jpc)
    # After ext2int, buses should be 1..nb
    for i in 1:nbuses(jpc_int)
        @test jpc_int.bus[i, :I] == Float64(i)
    end

    # Round-trip
    jpc_ext = int2ext(jpc_int, i2e)
    for i in 1:nbuses(jpc_ext)
        @test Int(jpc_ext.bus[i, :I]) == orig_bus_ids[i]
    end
end

@testset "renumber!" begin
    jpc = case5()
    # Manually set non-contiguous bus numbers
    jpc.bus[1, :I] = 10.0
    jpc.bus[2, :I] = 20.0
    jpc.bus[3, :I] = 30.0
    jpc.bus[4, :I] = 40.0
    jpc.bus[5, :I] = 50.0
    # Update branch references
    jpc.branch[1, :F_BUS] = 10.0; jpc.branch[1, :T_BUS] = 20.0
    jpc.gen[1, :GEN_BUS] = 10.0

    jpc, i2e = renumber!(jpc)
    @test jpc.bus[1, :I] == 1.0
    @test jpc.bus[5, :I] == 5.0
    @test i2e[1] == 10
    @test i2e[5] == 50
end

@testset "ext2int/int2ext - sgen BUS column" begin
    # Test sgen uses BUS (column 2) not ID (column 1)
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(2)
    jpc.bus[1, :I] = 100.0  # External bus ID
    jpc.bus[1, :TYPE] = 3.0
    jpc.bus[2, :I] = 200.0
    jpc.bus[2, :TYPE] = 1.0
    
    jpc.sgen = ComponentMatrix{SgenSchema, Float64}(1)
    jpc.sgen[1, :ID] = 999.0        # ID (col 1) - should NOT be remapped
    jpc.sgen[1, :BUS] = 200.0       # BUS (col 2) - should be remapped
    jpc.sgen[1, :IN_SERVICE] = 1.0
    
    jpc_int, i2e = ext2int(jpc)
    
    # ID should be unchanged
    @test jpc_int.sgen[1, :ID] == 999.0
    # BUS should be remapped to internal (1 or 2)
    @test jpc_int.sgen[1, :BUS] ∈ [1.0, 2.0]
    # Verify round-trip
    jpc_ext = int2ext(jpc_int, i2e)
    @test jpc_ext.sgen[1, :BUS] == 200.0
end

@testset "ext2int/int2ext - converter/dcdc/er_port" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(3)
    jpc.bus[1, :I] = 100.0; jpc.bus[1, :TYPE] = 3.0
    jpc.bus[2, :I] = 200.0; jpc.bus[2, :TYPE] = 1.0
    jpc.bus[3, :I] = 300.0; jpc.bus[3, :TYPE] = 1.0
    
    # Converter (ConverterSchema: ACBUS, DCBUS)
    jpc.converter = ComponentMatrix{ConverterSchema, Float64}(1)
    jpc.converter[1, :ACBUS] = 100.0
    jpc.converter[1, :DCBUS] = 200.0
    jpc.converter[1, :INSERVICE] = 1.0
    
    # DCDC (DCDCSchema: BUS_IN, BUS_OUT)
    jpc.dcdc = ComponentMatrix{DCDCSchema, Float64}(1)
    jpc.dcdc[1, :BUS_IN] = 200.0
    jpc.dcdc[1, :BUS_OUT] = 300.0
    jpc.dcdc[1, :INSERVICE] = 1.0
    
    # Switch (SwitchSchema: BUS_FROM, BUS_TO)
    jpc.switch = ComponentMatrix{SwitchSchema, Float64}(1)
    jpc.switch[1, :BUS_FROM] = 100.0
    jpc.switch[1, :BUS_TO] = 200.0
    jpc.switch[1, :IN_SERVICE] = 1.0
    
    # ERPort (ERPortSchema: BUS)
    jpc.er_port = ComponentMatrix{ERPortSchema, Float64}(1)
    jpc.er_port[1, :BUS] = 300.0
    jpc.er_port[1, :INSERVICE] = 1.0
    
    # ExtGrid
    jpc.ext_grid = ComponentMatrix{ExtGridSchema, Float64}(1)
    jpc.ext_grid[1, :BUS] = 100.0
    jpc.ext_grid[1, :STATUS] = 1.0
    
    jpc_int, i2e = ext2int(jpc)
    
    # Verify internal numbering (1, 2, 3)
    @test jpc_int.converter[1, :ACBUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.converter[1, :DCBUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.dcdc[1, :BUS_IN] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.dcdc[1, :BUS_OUT] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.switch[1, :BUS_FROM] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.switch[1, :BUS_TO] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.er_port[1, :BUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.ext_grid[1, :BUS] ∈ [1.0, 2.0, 3.0]
    
    # Round-trip
    jpc_ext = int2ext(jpc_int, i2e)
    @test jpc_ext.converter[1, :ACBUS] == 100.0
    @test jpc_ext.converter[1, :DCBUS] == 200.0
    @test jpc_ext.dcdc[1, :BUS_IN] == 200.0
    @test jpc_ext.dcdc[1, :BUS_OUT] == 300.0
    @test jpc_ext.switch[1, :BUS_FROM] == 100.0
    @test jpc_ext.switch[1, :BUS_TO] == 200.0
    @test jpc_ext.er_port[1, :BUS] == 300.0
    @test jpc_ext.ext_grid[1, :BUS] == 100.0
end

@testset "ext2int/int2ext - trafo" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(3)
    jpc.bus[1, :I] = 100.0; jpc.bus[1, :TYPE] = 3.0
    jpc.bus[2, :I] = 200.0; jpc.bus[2, :TYPE] = 1.0
    jpc.bus[3, :I] = 300.0; jpc.bus[3, :TYPE] = 1.0
    
    # Trafo2W
    jpc.trafo = ComponentMatrix{Trafo2WSchema, Float64}(1)
    jpc.trafo[1, :HV_BUS] = 100.0
    jpc.trafo[1, :LV_BUS] = 200.0
    jpc.trafo[1, :BR_STATUS] = 1.0
    
    # Trafo3W
    jpc.trafo3w = ComponentMatrix{Trafo3WSchema, Float64}(1)
    jpc.trafo3w[1, :HV_BUS] = 100.0
    jpc.trafo3w[1, :MV_BUS] = 200.0
    jpc.trafo3w[1, :LV_BUS] = 300.0
    jpc.trafo3w[1, :BR_STATUS] = 1.0
    
    jpc_int, i2e = ext2int(jpc)
    
    # Verify internal numbering
    @test jpc_int.trafo[1, :HV_BUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.trafo[1, :LV_BUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.trafo3w[1, :HV_BUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.trafo3w[1, :MV_BUS] ∈ [1.0, 2.0, 3.0]
    @test jpc_int.trafo3w[1, :LV_BUS] ∈ [1.0, 2.0, 3.0]
    
    # Round-trip
    jpc_ext = int2ext(jpc_int, i2e)
    @test jpc_ext.trafo[1, :HV_BUS] == 100.0
    @test jpc_ext.trafo[1, :LV_BUS] == 200.0
    @test jpc_ext.trafo3w[1, :HV_BUS] == 100.0
    @test jpc_ext.trafo3w[1, :MV_BUS] == 200.0
    @test jpc_ext.trafo3w[1, :LV_BUS] == 300.0
end
