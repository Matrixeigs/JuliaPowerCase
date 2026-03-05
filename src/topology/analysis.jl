# ═══════════════════════════════════════════════════════════════════════════════
# Topology Analysis — Graph-based metrics
# ═══════════════════════════════════════════════════════════════════════════════
# Uses Graphs.jl when available (optional dependency).
# Core adjacency / degree utilities are always available.

"""
    adjacency_list(jpc::PowerCaseData{K,T}) -> Vector{Vector{Int}}

Build an adjacency list (internal indices) from in-service branches.
"""
function adjacency_list(jpc::PowerCaseData{K, T}) where {K, T}
    nb = nrows(jpc.bus)
    e2i = Dict{Int, Int}()
    for i in 1:nb
        e2i[Int(jpc.bus[i, :I])] = i
    end

    adj = [Int[] for _ in 1:nb]
    for br in 1:nrows(jpc.branch)
        jpc.branch[br, :STATUS] == T(0) && continue
        fi = get(e2i, Int(jpc.branch[br, :F_BUS]), 0)
        ti = get(e2i, Int(jpc.branch[br, :T_BUS]), 0)
        if fi != 0 && ti != 0
            push!(adj[fi], ti)
            push!(adj[ti], fi)
        end
    end
    return adj
end

"""
    degree_vector(jpc::PowerCaseData) -> Vector{Int}

Node degree for each internal bus.
"""
function degree_vector(jpc::PowerCaseData)
    adj = adjacency_list(jpc)
    return [length(a) for a in adj]
end

"""
    n_connected_components(jpc::PowerCaseData) -> Int

Number of connected components (islands).
"""
function n_connected_components(jpc::PowerCaseData{AC, T}) where T
    groups, _ = find_islands(jpc)
    return length(groups)
end

"""
    is_connected(jpc::PowerCaseData{AC}) -> Bool

True if the AC system forms a single connected component.
"""
function is_connected(jpc::PowerCaseData{AC, T}) where T
    return n_connected_components(jpc) == 1
end

"""
    leaf_buses(jpc::PowerCaseData) -> Vector{Int}

Return external bus IDs of degree-1 (leaf / radial-end) buses.
"""
function leaf_buses(jpc::PowerCaseData{K, T}) where {K, T}
    adj = adjacency_list(jpc)
    nb = nrows(jpc.bus)
    leaves = Int[]
    for i in 1:nb
        if length(adj[i]) == 1
            push!(leaves, Int(jpc.bus[i, :I]))
        end
    end
    return leaves
end

"""
    is_radial(jpc::PowerCaseData{AC}) -> Bool

True if the network is a tree (|E| == |V| - 1 for connected graph).
"""
function is_radial(jpc::PowerCaseData{AC, T}) where T
    !is_connected(jpc) && return false
    nb = nrows(jpc.bus)
    ne = count(i -> jpc.branch[i, :STATUS] != T(0), 1:nrows(jpc.branch))
    return ne == nb - 1
end

"""
    topology_summary(jpc::PowerCaseData{AC,T}) -> NamedTuple

Quick topology metrics: buses, branches, components, radial, max/min/mean degree.
"""
function topology_summary(jpc::PowerCaseData{AC, T}) where T
    deg = degree_vector(jpc)
    nc = n_connected_components(jpc)
    nb = nrows(jpc.bus)
    ne = count(i -> jpc.branch[i, :STATUS] != T(0), 1:nrows(jpc.branch))
    (
        buses       = nb,
        branches    = ne,
        components  = nc,
        is_radial   = (nc == 1 && ne == nb - 1),
        max_degree  = isempty(deg) ? 0 : maximum(deg),
        min_degree  = isempty(deg) ? 0 : minimum(deg),
        mean_degree = isempty(deg) ? 0.0 : sum(deg) / length(deg),
    )
end
