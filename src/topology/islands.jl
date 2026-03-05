# ═══════════════════════════════════════════════════════════════════════════════
# Island Detection — DFS-based connected components
# ═══════════════════════════════════════════════════════════════════════════════

"""
    find_islands(jpc::PowerCaseData{AC}) -> (groups, isolated)

Find connected components (islands) in the AC system using DFS.

Returns:
- `groups`: `Vector{Vector{Int}}` of external bus numbers per island
- `isolated`: `Vector{Int}` of isolated bus numbers (no power source)
"""
function find_islands(jpc::PowerCaseData{AC, T}) where T
    nb = nrows(jpc.bus)
    nl = nrows(jpc.branch)
    nb == 0 && return Vector{Int}[], Int[]

    # External → internal mapping
    e2i = Dict{Int, Int}()
    for i in 1:nb
        e2i[Int(jpc.bus[i, :I])] = i
    end
    i2e = [Int(jpc.bus[i, :I]) for i in 1:nb]

    # Build adjacency list from in-service branches
    adj = [Int[] for _ in 1:nb]
    for br in 1:nl
        jpc.branch[br, :STATUS] == T(0) && continue
        fi = get(e2i, Int(jpc.branch[br, :F_BUS]), 0)
        ti = get(e2i, Int(jpc.branch[br, :T_BUS]), 0)
        if fi != 0 && ti != 0
            push!(adj[fi], ti)
            push!(adj[ti], fi)
        end
    end

    # DFS connected components
    visited = falses(nb)
    groups = Vector{Vector{Int}}()
    isolated = Int[]

    for u in 1:nb
        visited[u] && continue
        stack = [u]
        visited[u] = true
        comp = Int[]
        while !isempty(stack)
            v = pop!(stack)
            push!(comp, v)
            for w in adj[v]
                if !visited[w]
                    visited[w] = true
                    push!(stack, w)
                end
            end
        end
        push!(groups, [i2e[i] for i in comp])
    end

    return groups, isolated
end

"""
    find_islands_dc(jpc::PowerCaseData{DC}) -> (groups, isolated)

Find connected components in the DC sub-system.
"""
function find_islands_dc(dc_bus, dc_branch)
    nb = nrows(dc_bus)
    nb == 0 && return Vector{Int}[], Int[]

    bus_id_to_idx = Dict{Int, Int}()
    for i in 1:nb
        bus_id_to_idx[Int(dc_bus[i, 1])] = i   # column 1 = bus number
    end
    bus_ids = [Int(dc_bus[i, 1]) for i in 1:nb]

    # Adjacency list
    adj = [Int[] for _ in 1:nb]
    for br in 1:nrows(dc_branch)
        fi = get(bus_id_to_idx, Int(dc_branch[br, 1]), 0)
        ti = get(bus_id_to_idx, Int(dc_branch[br, 2]), 0)
        if fi != 0 && ti != 0
            push!(adj[fi], ti)
            push!(adj[ti], fi)
        end
    end

    # DFS
    visited = falses(nb)
    groups = Vector{Vector{Int}}()
    isolated = Int[]
    for u in 1:nb
        visited[u] && continue
        stack = [u]
        visited[u] = true
        comp = Int[]
        while !isempty(stack)
            v = pop!(stack)
            push!(comp, v)
            for w in adj[v]
                if !visited[w]
                    visited[w] = true
                    push!(stack, w)
                end
            end
        end
        push!(groups, sort!([bus_ids[i] for i in comp]))
    end
    return groups, isolated
end

"""
    find_islands_acdc(jpc_ac, dc_bus, dc_branch, vsc_converters)

Find connected components across the hybrid AC/DC system.
VSC converters link AC and DC buses in a unified graph.

Returns AC-side groups with external bus numbering.
"""
function find_islands_acdc(jpc::PowerCaseData{AC, T}, h::HybridPowerCaseData{T}) where T
    nb_ac = nrows(jpc.bus)
    nb_dc = nrows(h.dc_bus)
    n_total = nb_ac + nb_dc
    n_total == 0 && return Vector{Int}[], Int[]

    # Unified index: 1:nb_ac = AC, nb_ac+1:n_total = DC
    ac_e2i = Dict{Int, Int}()
    for i in 1:nb_ac
        ac_e2i[Int(jpc.bus[i, :I])] = i
    end
    dc_e2i = Dict{Int, Int}()
    for i in 1:nb_dc
        dc_e2i[Int(h.dc_bus[i, 1])] = nb_ac + i
    end

    # Build adjacency list
    adj = [Int[] for _ in 1:n_total]

    # AC branches
    for br in 1:nrows(jpc.branch)
        jpc.branch[br, :STATUS] == T(0) && continue
        fi = get(ac_e2i, Int(jpc.branch[br, :F_BUS]), 0)
        ti = get(ac_e2i, Int(jpc.branch[br, :T_BUS]), 0)
        if fi != 0 && ti != 0
            push!(adj[fi], ti); push!(adj[ti], fi)
        end
    end

    # DC branches
    for br in 1:nrows(h.dc_branch)
        fi = get(dc_e2i, Int(h.dc_branch[br, 1]), 0)
        ti = get(dc_e2i, Int(h.dc_branch[br, 2]), 0)
        if fi != 0 && ti != 0
            push!(adj[fi], ti); push!(adj[ti], fi)
        end
    end

    # VSC converters link AC ↔ DC
    for c in 1:nrows(h.vsc)
        ac_idx = get(ac_e2i, Int(h.vsc[c, 1]), 0)   # col 1 = ac_bus
        dc_idx = get(dc_e2i, Int(h.vsc[c, 2]), 0)   # col 2 = dc_bus
        if ac_idx != 0 && dc_idx != 0
            push!(adj[ac_idx], dc_idx); push!(adj[dc_idx], ac_idx)
        end
    end

    # DFS on unified graph
    visited = falses(n_total)
    groups = Vector{Vector{Int}}()
    for u in 1:n_total
        visited[u] && continue
        stack = [u]
        visited[u] = true
        ac_comp = Int[]
        while !isempty(stack)
            v = pop!(stack)
            # Only collect AC buses for the groups
            if v <= nb_ac
                push!(ac_comp, Int(jpc.bus[v, :I]))
            end
            for w in adj[v]
                if !visited[w]
                    visited[w] = true
                    push!(stack, w)
                end
            end
        end
        !isempty(ac_comp) && push!(groups, sort!(ac_comp))
    end

    return groups, Int[]
end
