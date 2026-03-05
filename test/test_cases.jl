using Test
using JuliaPowerCase

@testset "Case5" begin
    jpc = case5()
    @test nbuses(jpc) == 5
    @test nbranches(jpc) == 7
    @test ngenerators(jpc) == 3
    @test jpc.bus[1, :I] == 1.0
    @test jpc.bus[1, :TYPE] == 3.0  # REF
    @test jpc.base_mva == 100.0
end

@testset "Case9" begin
    jpc = case9()
    @test nbuses(jpc) == 9
    @test nbranches(jpc) == 9
    @test ngenerators(jpc) == 3
end

@testset "Case14" begin
    jpc = case14()
    @test nbuses(jpc) == 14
    @test nbranches(jpc) == 20
    @test ngenerators(jpc) == 5
end

@testset "IEEE 13-bus Distribution" begin
    jpc = case_ieee13()
    @test nbuses(jpc) == 13
    @test nbranches(jpc) == 12
    @test ngenerators(jpc) == 1
    @test jpc.base_mva == 10.0
end

@testset "IEEE 33-bus Distribution" begin
    jpc = case_ieee33()
    @test nbuses(jpc) == 33
    @test nbranches(jpc) == 32
    @test ngenerators(jpc) == 1
end

@testset "Hybrid AC/DC" begin
    h = case_hybrid_5ac3dc()
    @test nbuses(h.ac) == 5
    @test nrows(h.dc_bus) == 3
    @test nrows(h.dc_branch) == 2
    @test nrows(h.vsc) == 2
    @test h.base_mva == 100.0
    
    # Semantic validation: VSC columns match VSCSchema
    # VSCSchema: BUS_AC, BUS_DC, P_MW, Q_MVAR, VM_AC_PU, VM_DC_PU, LOSS_PERCENT, ...
    @test h.vsc[1, :BUS_AC] == 3.0    # AC bus 3
    @test h.vsc[1, :BUS_DC] == 101.0  # DC bus 101
    @test h.vsc[1, :P_MW] == 30.0     # Power 30 MW (not status!)
    @test h.vsc[1, :Q_MVAR] == 10.0   # Reactive 10 MVAr
    @test h.vsc[1, :VM_AC_PU] == 1.0  # AC voltage setpoint
    @test h.vsc[2, :BUS_AC] == 5.0    # AC bus 5
    @test h.vsc[2, :BUS_DC] == 103.0  # DC bus 103
    @test h.vsc[2, :IN_SERVICE] == 1.0  # In service
end
