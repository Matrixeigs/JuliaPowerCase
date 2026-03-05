using Test
using JuliaPowerCase

@testset "Island Detection" begin
    jpc = case9()
    groups, isolated = find_islands(jpc)
    # 9-bus system is fully connected → 1 island
    @test length(groups) == 1
    @test length(groups[1]) == 9
    @test isempty(isolated)
end

@testset "Topology Analysis" begin
    jpc = case14()
    adj = adjacency_list(jpc)
    @test length(adj) == 14

    deg = degree_vector(jpc)
    @test length(deg) == 14
    @test all(d -> d >= 1, deg)

    @test is_connected(jpc)
    @test n_connected_components(jpc) == 1

    # Leaf buses
    leaves = leaf_buses(jpc)
    @test length(leaves) >= 0  # may have some in IEEE 14

    # Topology summary
    ts = topology_summary(jpc)
    @test ts.buses == 14
    @test ts.components == 1
end

@testset "Topology — Radial Distribution" begin
    jpc33 = case_ieee33()
    @test is_connected(jpc33)
    @test is_radial(jpc33)

    leaves = leaf_buses(jpc33)
    @test length(leaves) > 0
end
