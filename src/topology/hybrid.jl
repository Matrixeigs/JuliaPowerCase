# ═══════════════════════════════════════════════════════════════════════════════
# Hybrid AC/DC Topology — Island Detection and Extraction for HybridPowerSystem
# ═══════════════════════════════════════════════════════════════════════════════

"""
    IslandInfo

Information about an electrically isolated island in a hybrid AC/DC system.

# Fields
- `id::Int`: Island identifier (1-based)
- `ac_buses::Vector{Int}`: AC bus indices in this island
- `dc_buses::Vector{Int}`: DC bus indices in this island
- `converters::Vector{Int}`: Converter indices connecting this island
- `has_ac_slack::Bool`: Whether island has an AC slack (REF_BUS) bus
- `has_dc_slack::Bool`: Whether island has DC buses (first DC bus acts as slack)
- `ac_slack_bus::Int`: Selected AC slack bus index (0 if none)
- `dc_slack_bus::Int`: Selected DC slack bus index (0 if none)
- `has_generators::Bool`: Whether island has any online generators
"""
struct IslandInfo
    id::Int
    ac_buses::Vector{Int}
    dc_buses::Vector{Int}
    converters::Vector{Int}
    has_ac_slack::Bool
    has_dc_slack::Bool
    ac_slack_bus::Int
    dc_slack_bus::Int
    has_generators::Bool
end

"""
    detect_islands(sys::HybridPowerSystem) -> Vector{IslandInfo}

Detect all electrically isolated islands in the hybrid AC/DC system.

Uses DFS on the **combined AC + DC + converter** graph so that converters
act as edges connecting their AC bus to their DC bus. This ensures that
a bus connected to the main system only through a converter is correctly
assigned to the same island.

DC buses are represented as internal nodes (nac+1):(nac+ndc) in the graph.

# Example
```julia
islands = detect_islands(sys)
for island in islands
    println("Island \$(island.id): \$(length(island.ac_buses)) AC buses, \$(length(island.dc_buses)) DC buses")
end
```
"""
function detect_islands(sys::HybridPowerSystem)
    nac = length(sys.ac.buses)
    ndc = length(sys.dc.buses)
    n_total = nac + ndc
    
    n_total == 0 && return IslandInfo[]
    
    # ── Build combined adjacency list ─────────────────────────────────
    # Nodes 1:nac = AC buses,  nac+1:nac+ndc = DC buses
    adj = [Int[] for _ in 1:n_total]
    
    # AC branches
    for br in sys.ac.branches
        br.in_service || continue
        push!(adj[br.from_bus], br.to_bus)
        push!(adj[br.to_bus], br.from_bus)
    end
    
    # DC branches
    for br in sys.dc.branches
        br.in_service || continue
        di = nac + br.from_bus
        dj = nac + br.to_bus
        push!(adj[di], dj)
        push!(adj[dj], di)
    end
    
    # VSC Converters act as edges: AC bus ↔ DC bus
    for conv in sys.vsc_converters
        conv.in_service || continue
        ac_node = conv.bus_ac
        dc_node = nac + conv.bus_dc
        push!(adj[ac_node], dc_node)
        push!(adj[dc_node], ac_node)
    end
    
    # ── DFS to find connected components ──────────────────────────────
    visited = falses(n_total)
    components = Vector{Vector{Int}}()
    
    for start in 1:n_total
        visited[start] && continue
        comp = Int[]
        stack = [start]
        while !isempty(stack)
            node = pop!(stack)
            visited[node] && continue
            visited[node] = true
            push!(comp, node)
            for nb in adj[node]
                visited[nb] || push!(stack, nb)
            end
        end
        push!(components, comp)
    end
    
    # ── Split each component into AC/DC bus sets and build IslandInfo ─
    islands = IslandInfo[]
    for comp in components
        ac_in_island = sort([n for n in comp if n <= nac])
        dc_in_island = sort([n - nac for n in comp if n > nac])
        
        # Skip pure-DC components with no AC buses
        isempty(ac_in_island) && continue
        
        ac_set = Set(ac_in_island)
        dc_set = Set(dc_in_island)
        
        # Converters belonging to this island
        conv_in_island = Int[]
        for (ci, conv) in enumerate(sys.vsc_converters)
            conv.in_service || continue
            if conv.bus_ac in ac_set || conv.bus_dc in dc_set
                push!(conv_in_island, ci)
            end
        end
        
        # Generator check - check AC generators
        has_generators = any(
            g.in_service && g.pg_mw > 0.0 && g.bus in ac_set
            for g in sys.ac.generators
        )
        # Also check bus types (PV/REF buses imply generation)
        if !has_generators
            has_generators = any(
                sys.ac.buses[i].bus_type == PV_BUS || sys.ac.buses[i].bus_type == REF_BUS
                for i in ac_in_island
            )
        end
        # Check converter power injection
        if !has_generators && !isempty(conv_in_island)
            has_generators = any(abs(sys.vsc_converters[ci].p_set_mw) > 0.0 for ci in conv_in_island)
        end
        
        has_ac_slack = any(sys.ac.buses[i].bus_type == REF_BUS for i in ac_in_island)
        has_dc_slack = !isempty(dc_in_island)
        
        ac_slack = 0
        if has_ac_slack
            idx = findfirst(i -> sys.ac.buses[i].bus_type == REF_BUS, ac_in_island)
            ac_slack = idx === nothing ? 0 : ac_in_island[idx]
        end
        dc_slack = isempty(dc_in_island) ? 0 : dc_in_island[1]
        
        id = length(islands) + 1
        push!(islands, IslandInfo(id, ac_in_island, dc_in_island,
                                  conv_in_island, has_ac_slack, has_dc_slack,
                                  ac_slack, dc_slack, has_generators))
    end
    
    return islands
end

"""
    extract_island_subsystem(sys::HybridPowerSystem, island::IslandInfo; slack_bus_override=0)
        -> (sub_sys, ac_map, dc_map)

Extract a standalone `HybridPowerSystem` for a single island.

# Arguments
- `sys`: The original hybrid system
- `island`: Island information from `detect_islands`
- `slack_bus_override`: If > 0, force this AC bus to be the slack (REF_BUS)

# Returns
- `sub_sys`: A new `HybridPowerSystem` containing only components in this island.
  All indices are renumbered starting from 1.
- `ac_map`: Dict mapping *original* AC bus index → sub-system AC bus index.
- `dc_map`: Dict mapping *original* DC bus index → sub-system DC bus index.

# Example
```julia
islands = detect_islands(sys)
for island in islands
    sub, ac_map, dc_map = extract_island_subsystem(sys, island)
    # Solve power flow on sub-system...
    # Map results back to original indices using ac_map, dc_map
end
```
"""
function extract_island_subsystem(sys::HybridPowerSystem, island::IslandInfo; 
                                  slack_bus_override::Int=0)
    # Build index maps: original → local (1-based)
    ac_map = Dict{Int,Int}()
    for (local_idx, orig_idx) in enumerate(sort(island.ac_buses))
        ac_map[orig_idx] = local_idx
    end
    dc_map = Dict{Int,Int}()
    for (local_idx, orig_idx) in enumerate(sort(island.dc_buses))
        dc_map[orig_idx] = local_idx
    end

    ac_set = Set(island.ac_buses)
    dc_set = Set(island.dc_buses)

    # ── AC buses (renumbered) ─────────────────────────────────────────
    sub_ac_buses = Bus{AC}[]
    for orig in sort(island.ac_buses)
        b = sys.ac.buses[orig]
        btype = orig == slack_bus_override ? REF_BUS : b.bus_type
        bva = orig == slack_bus_override ? 0.0 : b.va_deg
        push!(sub_ac_buses, Bus{AC}(
            index=ac_map[orig], bus_type=btype,
            pd_mw=b.pd_mw, qd_mvar=b.qd_mvar,
            vm_pu=b.vm_pu, va_deg=bva, area=b.area,
            base_kv=b.base_kv, vmax_pu=b.vmax_pu, vmin_pu=b.vmin_pu,
            gs_mw=b.gs_mw, bs_mvar=b.bs_mvar,
            zone=b.zone, in_service=b.in_service, name=b.name
        ))
    end

    # ── AC branches (only those with both ends inside this island) ────
    sub_ac_branches = Branch{AC}[]
    for br in sys.ac.branches
        br.in_service || continue
        (br.from_bus in ac_set && br.to_bus in ac_set) || continue
        push!(sub_ac_branches, Branch{AC}(
            index=length(sub_ac_branches)+1,
            from_bus=ac_map[br.from_bus], to_bus=ac_map[br.to_bus],
            r_pu=br.r_pu, x_pu=br.x_pu, b_pu=br.b_pu,
            tap=br.tap, in_service=br.in_service
        ))
    end

    # ── DC buses (renumbered) ─────────────────────────────────────────
    sub_dc_buses = Bus{DC}[]
    for orig in sort(island.dc_buses)
        b = sys.dc.buses[orig]
        push!(sub_dc_buses, Bus{DC}(
            index=dc_map[orig], vm_pu=b.vm_pu, pd_mw=b.pd_mw,
            in_service=b.in_service
        ))
    end

    # ── DC branches ───────────────────────────────────────────────────
    sub_dc_branches = Branch{DC}[]
    for br in sys.dc.branches
        br.in_service || continue
        (br.from_bus in dc_set && br.to_bus in dc_set) || continue
        push!(sub_dc_branches, Branch{DC}(
            index=length(sub_dc_branches)+1,
            from_bus=dc_map[br.from_bus], to_bus=dc_map[br.to_bus],
            r_pu=br.r_pu, in_service=br.in_service
        ))
    end

    # ── VSC Converters (only those with both AC and DC bus inside) ────
    sub_converters = VSCConverter[]
    for conv in sys.vsc_converters
        conv.in_service || continue
        (conv.bus_ac in ac_set && conv.bus_dc in dc_set) || continue
        push!(sub_converters, VSCConverter(
            index=length(sub_converters)+1,
            bus_ac=ac_map[conv.bus_ac], bus_dc=dc_map[conv.bus_dc],
            control_mode=conv.control_mode,
            p_set_mw=conv.p_set_mw, q_set_mvar=conv.q_set_mvar,
            v_dc_set_pu=conv.v_dc_set_pu, v_ac_set_pu=conv.v_ac_set_pu,
            loss_mw=conv.loss_mw, loss_percent=conv.loss_percent, eta=conv.eta,
            p_rated_mw=conv.p_rated_mw, in_service=conv.in_service,
            k_vdc=conv.k_vdc
        ))
    end

    # ── AC Generators (remap bus index) ───────────────────────────────
    sub_ac_generators = Generator[]
    for gen in sys.ac.generators
        gen.in_service || continue
        haskey(ac_map, gen.bus) || continue
        push!(sub_ac_generators, Generator(
            index=length(sub_ac_generators)+1,
            bus=ac_map[gen.bus],
            pg_mw=gen.pg_mw, qg_mvar=gen.qg_mvar,
            vg_pu=gen.vg_pu, mbase_mva=gen.mbase_mva,
            pmax_mw=gen.pmax_mw, pmin_mw=gen.pmin_mw,
            qmax_mvar=gen.qmax_mvar, qmin_mvar=gen.qmin_mvar,
            in_service=gen.in_service, is_slack=gen.is_slack,
            name=gen.name
        ))
    end

    # ── Build sub-system ──────────────────────────────────────────────
    sub_ac = PowerSystem{AC}(
        buses=sub_ac_buses,
        branches=sub_ac_branches,
        generators=sub_ac_generators,
        base_mva=sys.base_mva
    )
    
    sub_dc = PowerSystem{DC}(
        buses=sub_dc_buses,
        branches=sub_dc_branches,
        base_mva=sys.base_mva
    )
    
    sub_sys = HybridPowerSystem(
        ac=sub_ac, dc=sub_dc,
        vsc_converters=sub_converters,
        name="$(sys.name)_island_$(island.id)",
        base_mva=sys.base_mva
    )

    return sub_sys, ac_map, dc_map
end

"""
    find_islands_acdc(sys::HybridPowerSystem) -> (ac_groups, dc_groups)

Find connected components in a hybrid AC/DC system, returning separate
AC and DC island groupings. This is a lower-level function; prefer
`detect_islands` for most use cases.

# Returns
- `ac_groups`: Vector of AC bus index vectors per island
- `dc_groups`: Vector of DC bus index vectors per island
"""
function find_islands_acdc(sys::HybridPowerSystem)
    islands = detect_islands(sys)
    ac_groups = [isl.ac_buses for isl in islands]
    dc_groups = [isl.dc_buses for isl in islands]
    return ac_groups, dc_groups
end
