using Test
using JuliaPowerCase

@testset "PowerSystem Container" begin
    sys = PowerSystem{AC}()
    @test nbuses(sys) == 0

    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, pd_mw=50.0))
    @test nbuses(sys) == 2

    push!(sys.generators, Generator(index=1, bus=1, pg_mw=100.0, pmax_mw=200.0))
    @test ngenerators(sys) == 1
    @test total_gen_capacity(sys) == 200.0

    push!(sys.loads, Load{AC}(index=1, bus=2, p_mw=50.0))
    @test total_load(sys) == 50.0

    # Show method
    buf = IOBuffer()
    show(buf, sys)
    @test occursin("PowerSystem{AC}", String(take!(buf)))
end

@testset "PowerCaseData Container" begin
    jpc = PowerCaseData{AC, Float64}()
    @test nbuses(jpc) == 0

    jpc.bus = ComponentMatrix{BusSchema, Float64}(3)
    jpc.bus[1, :I] = 1.0; jpc.bus[1, :TYPE] = 3.0; jpc.bus[1, :VM] = 1.06
    jpc.bus[2, :I] = 2.0; jpc.bus[2, :TYPE] = 2.0; jpc.bus[2, :VM] = 1.04
    jpc.bus[3, :I] = 3.0; jpc.bus[3, :TYPE] = 1.0; jpc.bus[3, :VM] = 1.00
    @test nbuses(jpc) == 3
    @test jpc.bus[1, :VM] == 1.06

    jpc.branch = ComponentMatrix{BranchSchema, Float64}(2)
    jpc.branch[1, :F_BUS] = 1.0; jpc.branch[1, :T_BUS] = 2.0; jpc.branch[1, :STATUS] = 1.0
    jpc.branch[2, :F_BUS] = 2.0; jpc.branch[2, :T_BUS] = 3.0; jpc.branch[2, :STATUS] = 1.0
    @test nbranches(jpc) == 2

    # Summary table
    st = summary_table(jpc)
    @test any(p -> p.first == :bus, st)

    # Show method
    buf = IOBuffer()
    show(buf, jpc)
    @test occursin("PowerCaseData", String(take!(buf)))
end

@testset "HybridPowerCaseData" begin
    h = HybridPowerCaseData{Float64}()
    @test h.base_mva == 100.0
    @test nbuses(h.ac) == 0
end

@testset "PowerSystem copy/deepcopy" begin
    sys = PowerSystem{AC}()
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, pd_mw=50.0))
    push!(sys.generators, Generator(index=1, bus=1, pg_mw=100.0))
    sys.name = "TestSystem"
    
    # Test copy
    sys_copy = copy(sys)
    @test sys_copy.name == sys.name
    @test nbuses(sys_copy) == nbuses(sys)
    @test ngenerators(sys_copy) == ngenerators(sys)
    
    # Modify copy, original should be unaffected (vectors are independent)
    push!(sys_copy.buses, Bus{AC}(index=3, bus_type=PQ_BUS))
    @test nbuses(sys_copy) == 3
    @test nbuses(sys) == 2  # Original unchanged
    
    # Test deepcopy
    sys_deep = deepcopy(sys)
    @test sys_deep.name == sys.name
    @test nbuses(sys_deep) == nbuses(sys)
    
    # Modify deepcopy
    push!(sys_deep.generators, Generator(index=2, bus=2, pg_mw=50.0))
    @test ngenerators(sys_deep) == 2
    @test ngenerators(sys) == 1  # Original unchanged
end

@testset "PowerCaseData copy/deepcopy" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(2)
    jpc.bus[1, :I] = 1.0; jpc.bus[1, :VM] = 1.05
    jpc.bus[2, :I] = 2.0; jpc.bus[2, :VM] = 1.02
    jpc.name = "TestCase"
    jpc.component_names[(:bus, 1)] = "Bus1"
    
    # Test copy
    jpc_copy = copy(jpc)
    @test jpc_copy.name == jpc.name
    @test nbuses(jpc_copy) == nbuses(jpc)
    @test jpc_copy.bus[1, :VM] == jpc.bus[1, :VM]
    @test jpc_copy.component_names[(:bus, 1)] == "Bus1"
    
    # Modify copy, original should be unaffected
    jpc_copy.bus[1, :VM] = 1.10
    @test jpc_copy.bus[1, :VM] == 1.10
    @test jpc.bus[1, :VM] == 1.05  # Original unchanged
    
    # Test deepcopy
    jpc_deep = deepcopy(jpc)
    @test jpc_deep.name == jpc.name
    jpc_deep.bus[2, :VM] = 1.08
    @test jpc_deep.bus[2, :VM] == 1.08
    @test jpc.bus[2, :VM] == 1.02  # Original unchanged
end
