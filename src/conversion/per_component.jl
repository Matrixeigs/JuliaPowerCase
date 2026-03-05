# ═══════════════════════════════════════════════════════════════════════════════
# Per-Component Conversions & Utilities
# ═══════════════════════════════════════════════════════════════════════════════

# ── Validation Constants ──────────────────────────────────────────────────────
"""Minimum allowable voltage magnitude (p.u.) for validation warnings."""
const VM_MIN_REALISTIC = 0.5

"""Maximum allowable voltage magnitude (p.u.) for validation warnings."""
const VM_MAX_REALISTIC = 1.5

"""Maximum allowable voltage bound (p.u.) for validation warnings."""
const VBOUND_MAX_REALISTIC = 2.0

"""Default large power limit (MW) for unbounded generators."""
const POWER_LIMIT_LARGE = 9999.0


"""
    component_table(jpc::PowerCaseData, component::Symbol) -> ComponentMatrix

Access a component table by symbol name.
"""
function component_table(jpc::PowerCaseData, component::Symbol)
    if component === :bus;        return jpc.bus
    elseif component === :branch; return jpc.branch
    elseif component === :gen;    return jpc.gen
    elseif component === :gencost; return jpc.gencost
    elseif component === :load;   return jpc.load
    elseif component === :sgen;   return jpc.sgen
    elseif component === :ext_grid; return jpc.ext_grid
    elseif component === :storage; return jpc.storage
    elseif component === :switch; return jpc.switch
    elseif component === :shunt;  return jpc.shunt
    elseif component === :trafo;  return jpc.trafo
    elseif component === :trafo3w; return jpc.trafo3w
    elseif component === :converter; return jpc.converter
    elseif component === :dcdc;   return jpc.dcdc
    elseif component === :energy_router; return jpc.energy_router
    elseif component === :er_port; return jpc.er_port
    else
        throw(ArgumentError("Unknown component: $component"))
    end
end

"""
    component_names(::Type{PowerCaseData})

Return a tuple of all component table names.
"""
component_names(::Type{<:PowerCaseData}) = (
    :bus, :branch, :gen, :gencost, :load, :sgen, :ext_grid,
    :storage, :switch, :shunt, :trafo, :trafo3w, :converter,
    :dcdc, :energy_router, :er_port,
)

"""
    summary_table(jpc::PowerCaseData) -> Vector{Pair{Symbol,Int}}

Return (component_name => row_count) for all non-empty tables.
"""
function summary_table(jpc::PowerCaseData)
    result = Pair{Symbol,Int}[]
    for name in component_names(typeof(jpc))
        mat = component_table(jpc, name)
        nr = nrows(mat)
        nr > 0 && push!(result, name => nr)
    end
    return result
end

"""
    merge_systems(jpc1::PowerCaseData{K,T}, jpc2::PowerCaseData{K,T}) -> PowerCaseData{K,T}

Merge two power systems of the same kind by concatenating their component matrices.

# Arguments
- `jpc1`: First power system (serves as base for metadata)
- `jpc2`: Second power system (indices will be offset)

# Returns
A new `PowerCaseData` containing all components from both systems.

# Index Handling
- Bus indices in `jpc2` are offset by rounding up `max(jpc1.bus.I)` to nearest 1000
- Component indices (branch, gen, load, storage, etc.) are offset to avoid collisions
- All bus references (F_BUS, T_BUS, GEN_BUS, etc.) are updated accordingly
- `component_names` sidecar is merged with appropriate index offsets

# Metadata Handling
- `name`: Concatenated as `"jpc1.name+jpc2.name"`
- `base_mva`, `base_kv`, `freq_hz`, `version`: Taken from `jpc1`

# Example
```julia
sys_a = case9()
sys_b = case14()
merged = merge_systems(sys_a, sys_b)
# Buses from sys_b will have IDs starting at 1000+
```

!!! warning
    This performs a naive merge. Use `renumber!` after merging to get
    contiguous internal numbering.
"""
function merge_systems(jpc1::PowerCaseData{K,T}, jpc2::PowerCaseData{K,T}) where {K, T}
    merged = PowerCaseData{K, T}()
    merged.name     = jpc1.name * "+" * jpc2.name
    merged.base_mva = jpc1.base_mva
    merged.base_kv  = jpc1.base_kv
    merged.freq_hz  = jpc1.freq_hz
    merged.version  = jpc1.version

    # Find max bus number in jpc1 for offset
    max_bus1 = maximum(jpc1.bus[i, :I] for i in 1:nrows(jpc1.bus); init=T(0))
    offset = Int(ceil(max_bus1 / 1000)) * 1000  # round up to nearest 1000

    # ── Merge bus ─────────────────────────────────────────────────────────
    nb1, nb2 = nrows(jpc1.bus), nrows(jpc2.bus)
    if nb1 + nb2 > 0
        merged.bus = ComponentMatrix{BusSchema, T}(nb1 + nb2)
        if nb1 > 0
            rawdata(merged.bus)[1:nb1, :] .= rawdata(jpc1.bus)
        end
        if nb2 > 0
            rawdata(merged.bus)[nb1+1:end, :] .= rawdata(jpc2.bus)
            # Offset bus indices in jpc2
            for i in nb1+1:nb1+nb2
                merged.bus[i, :I] += T(offset)
            end
        end
    end

    # ── Merge branch ──────────────────────────────────────────────────────
    nbr1, nbr2 = nrows(jpc1.branch), nrows(jpc2.branch)
    max_br_id1 = nbr1 > 0 ? maximum(jpc1.branch[i, :INDEX] for i in 1:nbr1) : T(0)
    br_id_offset = max_br_id1
    
    if nbr1 + nbr2 > 0
        merged.branch = ComponentMatrix{BranchSchema, T}(nbr1 + nbr2)
        if nbr1 > 0
            rawdata(merged.branch)[1:nbr1, :] .= rawdata(jpc1.branch)
        end
        if nbr2 > 0
            rawdata(merged.branch)[nbr1+1:end, :] .= rawdata(jpc2.branch)
            # Offset bus references and INDEX
            for i in nbr1+1:nbr1+nbr2
                merged.branch[i, :INDEX] += br_id_offset
                merged.branch[i, :F_BUS] += T(offset)
                merged.branch[i, :T_BUS] += T(offset)
            end
        end
    end

    # ── Merge gen ─────────────────────────────────────────────────────────
    ng1, ng2 = nrows(jpc1.gen), nrows(jpc2.gen)
    max_gen_id1 = ng1 > 0 ? maximum(jpc1.gen[i, :INDEX] for i in 1:ng1) : T(0)
    gen_id_offset = max_gen_id1
    
    if ng1 + ng2 > 0
        merged.gen = ComponentMatrix{GenSchema, T}(ng1 + ng2)
        if ng1 > 0
            rawdata(merged.gen)[1:ng1, :] .= rawdata(jpc1.gen)
        end
        if ng2 > 0
            rawdata(merged.gen)[ng1+1:end, :] .= rawdata(jpc2.gen)
            for i in ng1+1:ng1+ng2
                merged.gen[i, :INDEX] += gen_id_offset
                merged.gen[i, :GEN_BUS] += T(offset)
            end
        end
    end

    # ── Merge load ────────────────────────────────────────────────────────
    nl1, nl2 = nrows(jpc1.load), nrows(jpc2.load)
    max_load_id1 = nl1 > 0 ? maximum(jpc1.load[i, :LOAD_I] for i in 1:nl1) : T(0)
    load_id_offset = max_load_id1
    
    if nl1 + nl2 > 0
        merged.load = ComponentMatrix{LoadSchema, T}(nl1 + nl2)
        if nl1 > 0
            rawdata(merged.load)[1:nl1, :] .= rawdata(jpc1.load)
        end
        if nl2 > 0
            rawdata(merged.load)[nl1+1:end, :] .= rawdata(jpc2.load)
            for i in nl1+1:nl1+nl2
                merged.load[i, :LOAD_I] += load_id_offset
                merged.load[i, :LOAD_BUS] += T(offset)
            end
        end
    end

    # ── Merge storage ─────────────────────────────────────────────────────
    ns1, ns2 = nrows(jpc1.storage), nrows(jpc2.storage)
    max_stor_id1 = ns1 > 0 ? maximum(jpc1.storage[i, :INDEX] for i in 1:ns1) : T(0)
    stor_id_offset = max_stor_id1
    
    if ns1 + ns2 > 0
        merged.storage = ComponentMatrix{StorageSchema, T}(ns1 + ns2)
        if ns1 > 0
            rawdata(merged.storage)[1:ns1, :] .= rawdata(jpc1.storage)
        end
        if ns2 > 0
            rawdata(merged.storage)[ns1+1:end, :] .= rawdata(jpc2.storage)
            for i in ns1+1:ns1+ns2
                merged.storage[i, :INDEX] += stor_id_offset
                merged.storage[i, :STOR_BUS] += T(offset)
            end
        end
    end

    # ── Merge sgen ────────────────────────────────────────────────────────
    nsg1, nsg2 = nrows(jpc1.sgen), nrows(jpc2.sgen)
    
    if nsg1 + nsg2 > 0
        merged.sgen = ComponentMatrix{SgenSchema, T}(nsg1 + nsg2)
        if nsg1 > 0
            rawdata(merged.sgen)[1:nsg1, :] .= rawdata(jpc1.sgen)
        end
        if nsg2 > 0
            rawdata(merged.sgen)[nsg1+1:end, :] .= rawdata(jpc2.sgen)
            for i in nsg1+1:nsg1+nsg2
                merged.sgen[i, :BUS] += T(offset)
            end
        end
    end

    # ── Merge ext_grid ────────────────────────────────────────────────────
    neg1, neg2 = nrows(jpc1.ext_grid), nrows(jpc2.ext_grid)
    max_eg_id1 = neg1 > 0 ? maximum(jpc1.ext_grid[i, :INDEX] for i in 1:neg1) : T(0)
    eg_id_offset = max_eg_id1
    
    if neg1 + neg2 > 0
        merged.ext_grid = ComponentMatrix{ExtGridSchema, T}(neg1 + neg2)
        if neg1 > 0
            rawdata(merged.ext_grid)[1:neg1, :] .= rawdata(jpc1.ext_grid)
        end
        if neg2 > 0
            rawdata(merged.ext_grid)[neg1+1:end, :] .= rawdata(jpc2.ext_grid)
            for i in neg1+1:neg1+neg2
                merged.ext_grid[i, :INDEX] += eg_id_offset
                merged.ext_grid[i, :BUS] += T(offset)
            end
        end
    end

    # ── Merge switch ──────────────────────────────────────────────────────
    nsw1, nsw2 = nrows(jpc1.switch), nrows(jpc2.switch)
    max_sw_id1 = nsw1 > 0 ? maximum(jpc1.switch[i, :INDEX] for i in 1:nsw1) : T(0)
    sw_id_offset = max_sw_id1
    
    if nsw1 + nsw2 > 0
        merged.switch = ComponentMatrix{SwitchSchema, T}(nsw1 + nsw2)
        if nsw1 > 0
            rawdata(merged.switch)[1:nsw1, :] .= rawdata(jpc1.switch)
        end
        if nsw2 > 0
            rawdata(merged.switch)[nsw1+1:end, :] .= rawdata(jpc2.switch)
            for i in nsw1+1:nsw1+nsw2
                merged.switch[i, :INDEX] += sw_id_offset
                merged.switch[i, :BUS_FROM] += T(offset)
                merged.switch[i, :BUS_TO] += T(offset)
            end
        end
    end

    # ── Merge shunt ───────────────────────────────────────────────────────
    nsh1, nsh2 = nrows(jpc1.shunt), nrows(jpc2.shunt)
    if nsh1 + nsh2 > 0
        merged.shunt = ComponentMatrix{ShuntSchema, T}(nsh1 + nsh2)
        if nsh1 > 0
            rawdata(merged.shunt)[1:nsh1, :] .= rawdata(jpc1.shunt)
        end
        if nsh2 > 0
            rawdata(merged.shunt)[nsh1+1:end, :] .= rawdata(jpc2.shunt)
            for i in nsh1+1:nsh1+nsh2
                merged.shunt[i, :BUS] += T(offset)
            end
        end
    end

    # ── Merge trafo ───────────────────────────────────────────────────────
    nt1, nt2 = nrows(jpc1.trafo), nrows(jpc2.trafo)
    if nt1 + nt2 > 0
        merged.trafo = ComponentMatrix{Trafo2WSchema, T}(nt1 + nt2)
        if nt1 > 0
            rawdata(merged.trafo)[1:nt1, :] .= rawdata(jpc1.trafo)
        end
        if nt2 > 0
            rawdata(merged.trafo)[nt1+1:end, :] .= rawdata(jpc2.trafo)
            for i in nt1+1:nt1+nt2
                merged.trafo[i, :HV_BUS] += T(offset)
                merged.trafo[i, :LV_BUS] += T(offset)
            end
        end
    end

    # ── Merge trafo3w ─────────────────────────────────────────────────────
    nt3w1, nt3w2 = nrows(jpc1.trafo3w), nrows(jpc2.trafo3w)
    if nt3w1 + nt3w2 > 0
        merged.trafo3w = ComponentMatrix{Trafo3WSchema, T}(nt3w1 + nt3w2)
        if nt3w1 > 0
            rawdata(merged.trafo3w)[1:nt3w1, :] .= rawdata(jpc1.trafo3w)
        end
        if nt3w2 > 0
            rawdata(merged.trafo3w)[nt3w1+1:end, :] .= rawdata(jpc2.trafo3w)
            for i in nt3w1+1:nt3w1+nt3w2
                merged.trafo3w[i, :HV_BUS] += T(offset)
                merged.trafo3w[i, :MV_BUS] += T(offset)
                merged.trafo3w[i, :LV_BUS] += T(offset)
            end
        end
    end

    # ── Merge gencost ─────────────────────────────────────────────────────
    ngc1, ngc2 = nrows(jpc1.gencost), nrows(jpc2.gencost)
    if ngc1 + ngc2 > 0
        merged.gencost = ComponentMatrix{GenCostSchema, T}(ngc1 + ngc2)
        if ngc1 > 0
            rawdata(merged.gencost)[1:ngc1, :] .= rawdata(jpc1.gencost)
        end
        if ngc2 > 0
            rawdata(merged.gencost)[ngc1+1:end, :] .= rawdata(jpc2.gencost)
            # gencost has no bus reference, just concatenate
        end
    end

    # ── Merge converter ───────────────────────────────────────────────────
    nc1, nc2 = nrows(jpc1.converter), nrows(jpc2.converter)
    max_vsc_id1 = nc1 > 0 ? maximum(jpc1.converter[i, :INDEX] for i in 1:nc1) : T(0)
    vsc_id_offset = max_vsc_id1  # IDs in jpc2 will be remapped
    
    if nc1 + nc2 > 0
        merged.converter = ComponentMatrix{ConverterSchema, T}(nc1 + nc2)
        if nc1 > 0
            rawdata(merged.converter)[1:nc1, :] .= rawdata(jpc1.converter)
        end
        if nc2 > 0
            rawdata(merged.converter)[nc1+1:end, :] .= rawdata(jpc2.converter)
            for i in nc1+1:nc1+nc2
                merged.converter[i, :INDEX] += vsc_id_offset
                merged.converter[i, :ACBUS] += T(offset)
                merged.converter[i, :DCBUS] += T(offset)
            end
        end
    end

    # ── Merge dcdc ────────────────────────────────────────────────────────
    ndc1, ndc2 = nrows(jpc1.dcdc), nrows(jpc2.dcdc)
    max_dcdc_id1 = ndc1 > 0 ? maximum(jpc1.dcdc[i, :INDEX] for i in 1:ndc1) : T(0)
    dcdc_id_offset = max_dcdc_id1  # IDs in jpc2 will be remapped
    
    if ndc1 + ndc2 > 0
        merged.dcdc = ComponentMatrix{DCDCSchema, T}(ndc1 + ndc2)
        if ndc1 > 0
            rawdata(merged.dcdc)[1:ndc1, :] .= rawdata(jpc1.dcdc)
        end
        if ndc2 > 0
            rawdata(merged.dcdc)[ndc1+1:end, :] .= rawdata(jpc2.dcdc)
            for i in ndc1+1:ndc1+ndc2
                merged.dcdc[i, :INDEX]   += dcdc_id_offset
                merged.dcdc[i, :BUS_IN]  += T(offset)
                merged.dcdc[i, :BUS_OUT] += T(offset)
            end
        end
    end

    # ── Merge energy_router ───────────────────────────────────────────────
    # Use max existing ER ID + 1 as offset, not bus offset, to avoid ID collisions
    ner1, ner2 = nrows(jpc1.energy_router), nrows(jpc2.energy_router)
    max_er_id1 = ner1 > 0 ? maximum(jpc1.energy_router[i, :ID] for i in 1:ner1) : T(0)
    er_id_offset = max_er_id1  # IDs in jpc2 will be remapped to max_id1 + original_id
    
    if ner1 + ner2 > 0
        merged.energy_router = ComponentMatrix{ERSchema, T}(ner1 + ner2)
        if ner1 > 0
            rawdata(merged.energy_router)[1:ner1, :] .= rawdata(jpc1.energy_router)
        end
        if ner2 > 0
            rawdata(merged.energy_router)[ner1+1:end, :] .= rawdata(jpc2.energy_router)
            # Remap ER IDs to avoid collision
            for i in ner1+1:ner1+ner2
                merged.energy_router[i, :ID] += er_id_offset
            end
        end
    end

    # ── Merge er_port ─────────────────────────────────────────────────────
    # Use max existing port ID + 1 as offset for port IDs
    nep1, nep2 = nrows(jpc1.er_port), nrows(jpc2.er_port)
    max_port_id1 = nep1 > 0 ? maximum(jpc1.er_port[i, :ID] for i in 1:nep1) : T(0)
    port_id_offset = max_port_id1
    
    if nep1 + nep2 > 0
        merged.er_port = ComponentMatrix{ERPortSchema, T}(nep1 + nep2)
        if nep1 > 0
            rawdata(merged.er_port)[1:nep1, :] .= rawdata(jpc1.er_port)
        end
        if nep2 > 0
            rawdata(merged.er_port)[nep1+1:end, :] .= rawdata(jpc2.er_port)
            for i in nep1+1:nep1+nep2
                merged.er_port[i, :ID]        += port_id_offset
                merged.er_port[i, :ROUTER_ID] += er_id_offset  # Use same offset as ER IDs
                merged.er_port[i, :BUS]       += T(offset)     # Bus still uses bus offset
            end
        end
    end

    # ── Merge component_names sidecar ─────────────────────────────────────
    # Copy names from jpc1 (unchanged keys)
    for ((ctype, idx), name) in jpc1.component_names
        merged.component_names[(ctype, idx)] = name
    end
    # Copy names from jpc2 (with index offset for affected types)
    for ((ctype, idx), name) in jpc2.component_names
        new_idx = if ctype == :bus
            idx + Int(offset)
        elseif ctype == :branch
            idx + Int(br_id_offset)
        elseif ctype == :gen
            idx + Int(gen_id_offset)
        elseif ctype == :load
            idx + Int(load_id_offset)
        elseif ctype == :storage
            idx + Int(stor_id_offset)
        elseif ctype == :sgen
            idx  # sgen IDs are not offset
        elseif ctype == :ext_grid
            idx + Int(eg_id_offset)
        elseif ctype == :switch
            idx + Int(sw_id_offset)
        elseif ctype == :vsc
            idx + Int(vsc_id_offset)
        elseif ctype == :dcdc
            idx + Int(dcdc_id_offset)
        elseif ctype == :energy_router
            idx + Int(er_id_offset)
        elseif ctype == :er_port
            idx + Int(port_id_offset)
        else
            idx
        end
        merged.component_names[(ctype, new_idx)] = name
    end

    return merged
end

"""
    deepcopy_case(jpc::PowerCaseData{K,T}) -> PowerCaseData{K,T}

Create a deep copy of a PowerCaseData, copying all matrix data.
"""
function deepcopy_case(jpc::PowerCaseData{K,T}) where {K, T}
    return deepcopy(jpc)
end

"""
    slice_buses(jpc::PowerCaseData{K,T}, bus_ids::Vector{Int}) -> PowerCaseData{K,T}

Extract a sub-system containing only the specified buses and their connected elements.

# Arguments
- `jpc`: Source power system to slice
- `bus_ids`: Vector of external bus IDs to include in the slice

# Returns
A new `PowerCaseData` containing only:
- Buses with IDs in `bus_ids`
- Branches with both endpoints in `bus_ids`
- Generators, loads, storage, sgen at buses in `bus_ids`
- Switches with both endpoints in `bus_ids`
- Transformers (2W, 3W) with all terminals in `bus_ids`
- Converters (VSC, DCDC) with all connected buses in `bus_ids`
- Energy routers with at least one retained port
- ERPorts at buses in `bus_ids`

# Metadata Handling
- `name`, `version`, `base_mva`, `base_kv`, `freq_hz`: Copied from source
- `component_names`: Filtered to retained components

# Example
```julia
full_sys = case14()
# Extract subsystem for buses 1-5
sub_sys = slice_buses(full_sys, [1, 2, 3, 4, 5])
```

!!! note
    Component indices are NOT renumbered. Call `ext2int` on the result
    if contiguous numbering is needed.
"""
function slice_buses(jpc::PowerCaseData{K,T}, bus_ids::Vector{Int}) where {K, T}
    sub = PowerCaseData{K, T}()
    sub.name     = jpc.name
    sub.version  = jpc.version
    sub.base_mva = jpc.base_mva
    sub.base_kv  = jpc.base_kv
    sub.freq_hz  = jpc.freq_hz

    bus_set = Set(T.(bus_ids))

    # Filter buses
    bus_rows = [i for i in 1:nrows(jpc.bus) if jpc.bus[i, :I] ∈ bus_set]
    if !isempty(bus_rows)
        sub.bus = ComponentMatrix{BusSchema, T}(length(bus_rows))
        for (j, i) in enumerate(bus_rows)
            rawdata(sub.bus)[j, :] .= rawdata(jpc.bus)[i, :]
        end
    end

    # Filter branches: both endpoints must be in bus_set
    br_rows = [i for i in 1:nrows(jpc.branch)
               if jpc.branch[i, :F_BUS] ∈ bus_set && jpc.branch[i, :T_BUS] ∈ bus_set]
    if !isempty(br_rows)
        sub.branch = ComponentMatrix{BranchSchema, T}(length(br_rows))
        for (j, i) in enumerate(br_rows)
            rawdata(sub.branch)[j, :] .= rawdata(jpc.branch)[i, :]
        end
    end

    # Filter generators
    gen_rows = [i for i in 1:nrows(jpc.gen) if jpc.gen[i, :GEN_BUS] ∈ bus_set]
    if !isempty(gen_rows)
        sub.gen = ComponentMatrix{GenSchema, T}(length(gen_rows))
        for (j, i) in enumerate(gen_rows)
            rawdata(sub.gen)[j, :] .= rawdata(jpc.gen)[i, :]
        end
    end

    # Filter loads
    ld_rows = [i for i in 1:nrows(jpc.load) if jpc.load[i, :LOAD_BUS] ∈ bus_set]
    if !isempty(ld_rows)
        sub.load = ComponentMatrix{LoadSchema, T}(length(ld_rows))
        for (j, i) in enumerate(ld_rows)
            rawdata(sub.load)[j, :] .= rawdata(jpc.load)[i, :]
        end
    end

    # Filter storage
    st_rows = [i for i in 1:nrows(jpc.storage) if jpc.storage[i, :STOR_BUS] ∈ bus_set]
    if !isempty(st_rows)
        sub.storage = ComponentMatrix{StorageSchema, T}(length(st_rows))
        for (j, i) in enumerate(st_rows)
            rawdata(sub.storage)[j, :] .= rawdata(jpc.storage)[i, :]
        end
    end

    # Filter sgen (static generators)
    sg_rows = [i for i in 1:nrows(jpc.sgen) if jpc.sgen[i, :BUS] ∈ bus_set]
    if !isempty(sg_rows)
        sub.sgen = ComponentMatrix{SgenSchema, T}(length(sg_rows))
        for (j, i) in enumerate(sg_rows)
            rawdata(sub.sgen)[j, :] .= rawdata(jpc.sgen)[i, :]
        end
    end

    # Filter ext_grid
    eg_rows = [i for i in 1:nrows(jpc.ext_grid) if jpc.ext_grid[i, :BUS] ∈ bus_set]
    if !isempty(eg_rows)
        sub.ext_grid = ComponentMatrix{ExtGridSchema, T}(length(eg_rows))
        for (j, i) in enumerate(eg_rows)
            rawdata(sub.ext_grid)[j, :] .= rawdata(jpc.ext_grid)[i, :]
        end
    end

    # Filter switch: both endpoints must be in bus_set
    sw_rows = [i for i in 1:nrows(jpc.switch)
               if jpc.switch[i, :BUS_FROM] ∈ bus_set && jpc.switch[i, :BUS_TO] ∈ bus_set]
    if !isempty(sw_rows)
        sub.switch = ComponentMatrix{SwitchSchema, T}(length(sw_rows))
        for (j, i) in enumerate(sw_rows)
            rawdata(sub.switch)[j, :] .= rawdata(jpc.switch)[i, :]
        end
    end

    # Filter shunt
    sh_rows = [i for i in 1:nrows(jpc.shunt) if jpc.shunt[i, :BUS] ∈ bus_set]
    if !isempty(sh_rows)
        sub.shunt = ComponentMatrix{ShuntSchema, T}(length(sh_rows))
        for (j, i) in enumerate(sh_rows)
            rawdata(sub.shunt)[j, :] .= rawdata(jpc.shunt)[i, :]
        end
    end

    # Filter trafo: both endpoints must be in bus_set
    tf_rows = [i for i in 1:nrows(jpc.trafo)
               if jpc.trafo[i, :HV_BUS] ∈ bus_set && jpc.trafo[i, :LV_BUS] ∈ bus_set]
    if !isempty(tf_rows)
        sub.trafo = ComponentMatrix{Trafo2WSchema, T}(length(tf_rows))
        for (j, i) in enumerate(tf_rows)
            rawdata(sub.trafo)[j, :] .= rawdata(jpc.trafo)[i, :]
        end
    end

    # Filter trafo3w: all three endpoints must be in bus_set
    t3w_rows = [i for i in 1:nrows(jpc.trafo3w)
                if jpc.trafo3w[i, :HV_BUS] ∈ bus_set && jpc.trafo3w[i, :MV_BUS] ∈ bus_set && jpc.trafo3w[i, :LV_BUS] ∈ bus_set]
    if !isempty(t3w_rows)
        sub.trafo3w = ComponentMatrix{Trafo3WSchema, T}(length(t3w_rows))
        for (j, i) in enumerate(t3w_rows)
            rawdata(sub.trafo3w)[j, :] .= rawdata(jpc.trafo3w)[i, :]
        end
    end

    # Filter converter (VSC): both AC and DC bus must be in bus_set
    cv_rows = [i for i in 1:nrows(jpc.converter)
               if jpc.converter[i, :ACBUS] ∈ bus_set && jpc.converter[i, :DCBUS] ∈ bus_set]
    if !isempty(cv_rows)
        sub.converter = ComponentMatrix{ConverterSchema, T}(length(cv_rows))
        for (j, i) in enumerate(cv_rows)
            rawdata(sub.converter)[j, :] .= rawdata(jpc.converter)[i, :]
        end
    end

    # Filter dcdc: both buses must be in bus_set
    dc_rows = [i for i in 1:nrows(jpc.dcdc)
               if jpc.dcdc[i, :BUS_IN] ∈ bus_set && jpc.dcdc[i, :BUS_OUT] ∈ bus_set]
    if !isempty(dc_rows)
        sub.dcdc = ComponentMatrix{DCDCSchema, T}(length(dc_rows))
        for (j, i) in enumerate(dc_rows)
            rawdata(sub.dcdc)[j, :] .= rawdata(jpc.dcdc)[i, :]
        end
    end

    # Filter er_port: include ports whose bus is in bus_set
    port_rows = [i for i in 1:nrows(jpc.er_port)
                 if jpc.er_port[i, :BUS] ∈ bus_set]
    retained_router_ids = Set{T}()
    # Count retained ports per router for NUM_PORTS update
    ports_per_router = Dict{T, Int}()
    if !isempty(port_rows)
        sub.er_port = ComponentMatrix{ERPortSchema, T}(length(port_rows))
        for (j, i) in enumerate(port_rows)
            rawdata(sub.er_port)[j, :] .= rawdata(jpc.er_port)[i, :]
            router_id = T(jpc.er_port[i, :ROUTER_ID])
            push!(retained_router_ids, router_id)
            ports_per_router[router_id] = get(ports_per_router, router_id, 0) + 1
        end
    end

    # Filter energy_router: include if any of its ports is retained
    # Also update NUM_PORTS to reflect actual retained port count
    er_rows = [i for i in 1:nrows(jpc.energy_router)
               if T(jpc.energy_router[i, :ID]) ∈ retained_router_ids]
    if !isempty(er_rows)
        sub.energy_router = ComponentMatrix{ERSchema, T}(length(er_rows))
        for (j, i) in enumerate(er_rows)
            rawdata(sub.energy_router)[j, :] .= rawdata(jpc.energy_router)[i, :]
            # Update NUM_PORTS to match actual retained port count
            router_id = T(jpc.energy_router[i, :ID])
            sub.energy_router[j, :NUM_PORTS] = T(get(ports_per_router, router_id, 0))
        end
    end

    # Filter gencost: keep corresponding to retained generators
    # Assumes 1:1 correspondence with gen table
    if !isempty(gen_rows) && nrows(jpc.gencost) > 0
        gc_rows = [i for i in gen_rows if i <= nrows(jpc.gencost)]
        if !isempty(gc_rows)
            sub.gencost = ComponentMatrix{GenCostSchema, T}(length(gc_rows))
            for (j, i) in enumerate(gc_rows)
                rawdata(sub.gencost)[j, :] .= rawdata(jpc.gencost)[i, :]
            end
        end
    end

    # ── Preserve component_names for retained components ──────────────────
    # Build sets of retained indices by component type
    retained_vsc_ids = Set{Int}()
    for i in 1:nrows(sub.converter)
        push!(retained_vsc_ids, Int(sub.converter[i, :INDEX]))
    end
    retained_dcdc_ids = Set{Int}()
    for i in 1:nrows(sub.dcdc)
        push!(retained_dcdc_ids, Int(sub.dcdc[i, :INDEX]))
    end
    retained_er_ids = Set{Int}()
    for i in 1:nrows(sub.energy_router)
        push!(retained_er_ids, Int(sub.energy_router[i, :ID]))
    end
    retained_port_ids = Set{Int}()
    for i in 1:nrows(sub.er_port)
        push!(retained_port_ids, Int(sub.er_port[i, :ID]))
    end
    
    for ((ctype, idx), name) in jpc.component_names
        retain = if ctype == :vsc
            idx ∈ retained_vsc_ids
        elseif ctype == :dcdc
            idx ∈ retained_dcdc_ids
        elseif ctype == :energy_router
            idx ∈ retained_er_ids
        elseif ctype == :er_port
            idx ∈ retained_port_ids
        else
            false
        end
        retain && (sub.component_names[(ctype, idx)] = name)
    end

    return sub
end

# ═══════════════════════════════════════════════════════════════════════════════
# Validation Utilities
# ═══════════════════════════════════════════════════════════════════════════════

"""
    ValidationError

Represents a validation error with its severity level and message.
"""
struct ValidationError
    level::Symbol       # :error or :warning
    component::Symbol   # :energy_router, :er_port, etc.
    message::String
end

"""
    validate_case(jpc::PowerCaseData; strict::Bool=false) -> Vector{ValidationError}

Validate the internal consistency of a PowerCaseData instance.

# Checks performed:
- **Bus Voltage Bounds**: VMIN ≤ VMAX, realistic voltage magnitudes
- **Generator Power Limits**: PMIN ≤ PMAX, QMIN ≤ QMAX, PG/QG within bounds
- **Branch FK Integrity**: F_BUS and T_BUS reference valid buses, no self-loops
- **Branch Impedance**: Non-negative resistance, non-zero impedance
- **Load FK Integrity**: LOAD_BUS references valid buses
- **Storage FK Integrity**: STOR_BUS references valid buses
- **ID Uniqueness**: EnergyRouter IDs must be unique
- **ERPort Reference Validity**: ROUTER_ID values reference existing EnergyRouters
- **NUM_PORTS Consistency**: EnergyRouter.NUM_PORTS matches actual port count

# Arguments
- `jpc`: The PowerCaseData instance to validate
- `strict`: If true, throws an error on the first validation failure

# Returns
A vector of `ValidationError` structs. Empty vector means valid.

# Examples
```julia
jpc = to_matrix(sys)
errors = validate_case(jpc)
if !isempty(errors)
    for e in errors
        println("[", e.level, "] ", e.component, ": ", e.message)
    end
end
```
"""
function validate_case(jpc::PowerCaseData{K,T}; strict::Bool=false) where {K,T}
    errors = ValidationError[]
    
    # ── Build valid bus set for FK checks ─────────────────────────────────
    valid_buses = Set{Int}(Int(jpc.bus[i, :I]) for i in 1:nrows(jpc.bus))
    
    # ── Bus voltage bounds check ──────────────────────────────────────────
    for i in 1:nrows(jpc.bus)
        vm = jpc.bus[i, :VM]
        vmin = jpc.bus[i, :VMIN]
        vmax = jpc.bus[i, :VMAX]
        bus_id = Int(jpc.bus[i, :I])
        
        if vmin > vmax
            err = ValidationError(:error, :bus,
                "Bus $bus_id: VMIN ($vmin) > VMAX ($vmax)")
            push!(errors, err)
            strict && error(err.message)
        end
        
        # Skip VM check if VM=0 (typically means uninitialized)
        if vm != T(0) && (vm < T(VM_MIN_REALISTIC) || vm > T(VM_MAX_REALISTIC))
            err = ValidationError(:warning, :bus,
                "Bus $bus_id: voltage magnitude VM=$vm outside typical range [$VM_MIN_REALISTIC, $VM_MAX_REALISTIC]")
            push!(errors, err)
        end
        
        if vmin < T(0) || vmax > T(VBOUND_MAX_REALISTIC)
            err = ValidationError(:warning, :bus,
                "Bus $bus_id: voltage bounds VMIN=$vmin, VMAX=$vmax seem unrealistic")
            push!(errors, err)
        end
    end
    
    # ── Generator power limits check ──────────────────────────────────────
    for i in 1:nrows(jpc.gen)
        pg = jpc.gen[i, :PG]
        pmax = jpc.gen[i, :PMAX]
        pmin = jpc.gen[i, :PMIN]
        qg = jpc.gen[i, :QG]
        qmax = jpc.gen[i, :QMAX]
        qmin = jpc.gen[i, :QMIN]
        gen_bus = Int(jpc.gen[i, :GEN_BUS])
        gen_idx = nrows(jpc.gen) > 0 && ncols(GenSchema) >= 1 ? Int(jpc.gen[i, :INDEX]) : i
        
        # Check FK reference
        if gen_bus ∉ valid_buses
            err = ValidationError(:error, :gen,
                "Gen $gen_idx: GEN_BUS=$gen_bus not in bus table")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if pmin > pmax
            err = ValidationError(:error, :gen,
                "Gen $gen_idx at bus $gen_bus: PMIN ($pmin) > PMAX ($pmax)")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if qmin > qmax
            err = ValidationError(:error, :gen,
                "Gen $gen_idx at bus $gen_bus: QMIN ($qmin) > QMAX ($qmax)")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if pg > pmax
            err = ValidationError(:warning, :gen,
                "Gen $gen_idx at bus $gen_bus: PG ($pg) > PMAX ($pmax)")
            push!(errors, err)
        end
        
        if pg < pmin
            err = ValidationError(:warning, :gen,
                "Gen $gen_idx at bus $gen_bus: PG ($pg) < PMIN ($pmin)")
            push!(errors, err)
        end
        
        if qg > qmax
            err = ValidationError(:warning, :gen,
                "Gen $gen_idx at bus $gen_bus: QG ($qg) > QMAX ($qmax)")
            push!(errors, err)
        end
        
        if qg < qmin
            err = ValidationError(:warning, :gen,
                "Gen $gen_idx at bus $gen_bus: QG ($qg) < QMIN ($qmin)")
            push!(errors, err)
        end
    end
    
    # ── Branch FK and impedance checks ────────────────────────────────────
    for i in 1:nrows(jpc.branch)
        f_bus = Int(jpc.branch[i, :F_BUS])
        t_bus = Int(jpc.branch[i, :T_BUS])
        r = jpc.branch[i, :BR_R]
        x = jpc.branch[i, :BR_X]
        br_idx = Int(jpc.branch[i, :INDEX])
        
        if f_bus ∉ valid_buses
            err = ValidationError(:error, :branch,
                "Branch $br_idx: F_BUS=$f_bus not in bus table")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if t_bus ∉ valid_buses
            err = ValidationError(:error, :branch,
                "Branch $br_idx: T_BUS=$t_bus not in bus table")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if f_bus == t_bus
            err = ValidationError(:error, :branch,
                "Branch $br_idx: F_BUS == T_BUS (self-loop)")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if r < T(0)
            err = ValidationError(:error, :branch,
                "Branch $br_idx: BR_R ($r) < 0")
            push!(errors, err)
            strict && error(err.message)
        end
        
        if r == T(0) && x == T(0)
            err = ValidationError(:warning, :branch,
                "Branch $br_idx: both R and X are zero (zero-impedance branch)")
            push!(errors, err)
        end
    end
    
    # ── Load FK checks ────────────────────────────────────────────────────
    for i in 1:nrows(jpc.load)
        load_bus = Int(jpc.load[i, :LOAD_BUS])
        load_idx = Int(jpc.load[i, :LOAD_I])
        
        if load_bus ∉ valid_buses
            err = ValidationError(:error, :load,
                "Load $load_idx: LOAD_BUS=$load_bus not in bus table")
            push!(errors, err)
            strict && error(err.message)
        end
    end
    
    # ── Storage FK checks ─────────────────────────────────────────────────
    for i in 1:nrows(jpc.storage)
        stor_bus = Int(jpc.storage[i, :STOR_BUS])
        stor_idx = Int(jpc.storage[i, :INDEX])
        
        if stor_bus ∉ valid_buses
            err = ValidationError(:error, :storage,
                "Storage $stor_idx: STOR_BUS=$stor_bus not in bus table")
            push!(errors, err)
            strict && error(err.message)
        end
    end
    
    # ── Check EnergyRouter ID uniqueness ──────────────────────────────────
    if nrows(jpc.energy_router) > 0
        er_ids = T[jpc.energy_router[i, :ID] for i in 1:nrows(jpc.energy_router)]
        id_counts = Dict{T,Int}()
        for id in er_ids
            id_counts[id] = get(id_counts, id, 0) + 1
        end
        for (id, count) in id_counts
            if count > 1
                err = ValidationError(:error, :energy_router, 
                    "Duplicate EnergyRouter ID=$id found $count times")
                push!(errors, err)
                strict && error(err.message)
            end
        end
    end
    
    # ── Check ERPort ROUTER_ID references valid EnergyRouter ──────────────
    if nrows(jpc.er_port) > 0 && nrows(jpc.energy_router) > 0
        valid_router_ids = Set{T}(jpc.energy_router[i, :ID] for i in 1:nrows(jpc.energy_router))
        for i in 1:nrows(jpc.er_port)
            router_id = T(jpc.er_port[i, :ROUTER_ID])
            if router_id ∉ valid_router_ids
                err = ValidationError(:error, :er_port,
                    "ERPort row $i references non-existent ROUTER_ID=$router_id")
                push!(errors, err)
                strict && error(err.message)
            end
        end
    elseif nrows(jpc.er_port) > 0 && nrows(jpc.energy_router) == 0
        err = ValidationError(:error, :er_port,
            "ERPort table has $(nrows(jpc.er_port)) rows but no EnergyRouters exist")
        push!(errors, err)
        strict && error(err.message)
    end
    
    # ── Check NUM_PORTS consistency ───────────────────────────────────────
    if nrows(jpc.energy_router) > 0
        # Count actual ports per router
        actual_port_counts = Dict{T,Int}()
        for i in 1:nrows(jpc.er_port)
            rid = T(jpc.er_port[i, :ROUTER_ID])
            actual_port_counts[rid] = get(actual_port_counts, rid, 0) + 1
        end
        
        for i in 1:nrows(jpc.energy_router)
            router_id = T(jpc.energy_router[i, :ID])
            declared = Int(jpc.energy_router[i, :NUM_PORTS])
            actual = get(actual_port_counts, router_id, 0)
            if declared != actual
                err = ValidationError(:warning, :energy_router,
                    "EnergyRouter ID=$router_id declares NUM_PORTS=$declared but has $actual actual ports")
                push!(errors, err)
                strict && error(err.message)
            end
        end
    end
    
    return errors
end

"""
    is_valid(jpc::PowerCaseData) -> Bool

Quick check if PowerCaseData passes all validation rules (errors only).
Warnings do not cause `is_valid` to return false.
"""
is_valid(jpc::PowerCaseData) = !any(e -> e.level == :error, validate_case(jpc))

"""
    has_warnings(jpc::PowerCaseData) -> Bool

Check if PowerCaseData has any validation warnings.
"""
has_warnings(jpc::PowerCaseData) = any(e -> e.level == :warning, validate_case(jpc))
