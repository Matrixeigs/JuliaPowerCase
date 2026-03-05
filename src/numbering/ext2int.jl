# ═══════════════════════════════════════════════════════════════════════════════
# External → Internal Numbering  (ext2int)
# ═══════════════════════════════════════════════════════════════════════════════
# Filters out-of-service elements and renumbers buses consecutively (1:nb).
# Uses SparseArrays.sparsevec for the e2i mapping vector.

using SparseArrays

"""
    ext2int(jpc::PowerCaseData{K,T}) -> (jpc_int, i2e)

Convert `jpc` from external (arbitrary) bus numbering to consecutive
internal numbering.  Returns:

- `jpc_int` — a deep-copied `PowerCaseData` with contiguous bus IDs
- `i2e`     — `Vector{Int}` mapping internal bus index → original external ID

Out-of-service buses, branches, generators, and loads are removed.
"""
function ext2int(jpc::PowerCaseData{K, T}) where {K, T}
    out = deepcopy(jpc)

    # ── Filter out-of-service elements ────────────────────────────────────
    _filter_oos!(out)

    nb = nrows(out.bus)
    nb == 0 && return out, Int[]

    # ── Validate FK references before remapping ───────────────────────────
    valid_buses = Set{Int}(Int(out.bus[i, :I]) for i in 1:nb)
    _validate_fk_references!(out, valid_buses)

    # ── Build e2i sparse mapping ──────────────────────────────────────────
    i2e = [Int(out.bus[i, :I]) for i in 1:nb]
    max_bus = maximum(i2e)
    e2i = sparsevec(i2e, collect(1:nb), max_bus)

    # ── Renumber all bus references ───────────────────────────────────────
    _remap_buses!(out, e2i, T)

    return out, i2e
end

"""
    _validate_fk_references!(jpc, valid_buses)

Validate that all bus references in jpc point to valid buses.
Throws ArgumentError with details if any FK violations found.
"""
function _validate_fk_references!(jpc::PowerCaseData{K, T}, valid_buses::Set{Int}) where {K, T}
    violations = String[]
    
    # Branch: F_BUS, T_BUS
    for i in 1:nrows(jpc.branch)
        f_bus = Int(jpc.branch[i, :F_BUS])
        t_bus = Int(jpc.branch[i, :T_BUS])
        f_bus ∉ valid_buses && push!(violations, "branch[$i]: F_BUS=$f_bus not in valid buses")
        t_bus ∉ valid_buses && push!(violations, "branch[$i]: T_BUS=$t_bus not in valid buses")
    end
    
    # Generator: GEN_BUS
    for i in 1:nrows(jpc.gen)
        bus = Int(jpc.gen[i, :GEN_BUS])
        bus ∉ valid_buses && push!(violations, "gen[$i]: GEN_BUS=$bus not in valid buses")
    end
    
    # Load: LOAD_BUS
    for i in 1:nrows(jpc.load)
        bus = Int(jpc.load[i, :LOAD_BUS])
        bus ∉ valid_buses && push!(violations, "load[$i]: LOAD_BUS=$bus not in valid buses")
    end
    
    # Storage: STOR_BUS
    for i in 1:nrows(jpc.storage)
        bus = Int(jpc.storage[i, :STOR_BUS])
        bus ∉ valid_buses && push!(violations, "storage[$i]: STOR_BUS=$bus not in valid buses")
    end
    
    # Shunt: BUS
    for i in 1:nrows(jpc.shunt)
        bus = Int(jpc.shunt[i, :BUS])
        bus ∉ valid_buses && push!(violations, "shunt[$i]: BUS=$bus not in valid buses")
    end
    
    # Static Generator: BUS
    for i in 1:nrows(jpc.sgen)
        bus = Int(jpc.sgen[i, :BUS])
        bus ∉ valid_buses && push!(violations, "sgen[$i]: BUS=$bus not in valid buses")
    end
    
    # External Grid: BUS
    for i in 1:nrows(jpc.ext_grid)
        bus = Int(jpc.ext_grid[i, :BUS])
        bus ∉ valid_buses && push!(violations, "ext_grid[$i]: BUS=$bus not in valid buses")
    end
    
    # Converter: ACBUS, DCBUS
    for i in 1:nrows(jpc.converter)
        ac_bus = Int(jpc.converter[i, :ACBUS])
        dc_bus = Int(jpc.converter[i, :DCBUS])
        ac_bus ∉ valid_buses && push!(violations, "converter[$i]: ACBUS=$ac_bus not in valid buses")
        dc_bus ∉ valid_buses && push!(violations, "converter[$i]: DCBUS=$dc_bus not in valid buses")
    end
    
    # DCDC: BUS_IN, BUS_OUT
    for i in 1:nrows(jpc.dcdc)
        bus_in = Int(jpc.dcdc[i, :BUS_IN])
        bus_out = Int(jpc.dcdc[i, :BUS_OUT])
        bus_in ∉ valid_buses && push!(violations, "dcdc[$i]: BUS_IN=$bus_in not in valid buses")
        bus_out ∉ valid_buses && push!(violations, "dcdc[$i]: BUS_OUT=$bus_out not in valid buses")
    end
    
    # Switch: BUS_FROM, BUS_TO
    for i in 1:nrows(jpc.switch)
        bf = Int(jpc.switch[i, :BUS_FROM])
        bt = Int(jpc.switch[i, :BUS_TO])
        bf ∉ valid_buses && push!(violations, "switch[$i]: BUS_FROM=$bf not in valid buses")
        bt ∉ valid_buses && push!(violations, "switch[$i]: BUS_TO=$bt not in valid buses")
    end
    
    # Trafo 2W: HV_BUS, LV_BUS
    for i in 1:nrows(jpc.trafo)
        hv = Int(jpc.trafo[i, :HV_BUS])
        lv = Int(jpc.trafo[i, :LV_BUS])
        hv ∉ valid_buses && push!(violations, "trafo[$i]: HV_BUS=$hv not in valid buses")
        lv ∉ valid_buses && push!(violations, "trafo[$i]: LV_BUS=$lv not in valid buses")
    end
    
    # Trafo 3W: HV_BUS, MV_BUS, LV_BUS
    for i in 1:nrows(jpc.trafo3w)
        hv = Int(jpc.trafo3w[i, :HV_BUS])
        mv = Int(jpc.trafo3w[i, :MV_BUS])
        lv = Int(jpc.trafo3w[i, :LV_BUS])
        hv ∉ valid_buses && push!(violations, "trafo3w[$i]: HV_BUS=$hv not in valid buses")
        mv ∉ valid_buses && push!(violations, "trafo3w[$i]: MV_BUS=$mv not in valid buses")
        lv ∉ valid_buses && push!(violations, "trafo3w[$i]: LV_BUS=$lv not in valid buses")
    end
    
    # ER Port: BUS
    for i in 1:nrows(jpc.er_port)
        bus = Int(jpc.er_port[i, :BUS])
        bus ∉ valid_buses && push!(violations, "er_port[$i]: BUS=$bus not in valid buses")
    end
    
    if !isempty(violations)
        msg = "ext2int: FK violation - elements reference buses removed as out-of-service:\n" *
              join(violations[1:min(10, length(violations))], "\n")
        if length(violations) > 10
            msg *= "\n... and $(length(violations) - 10) more violations"
        end
        throw(ArgumentError(msg))
    end
end

"""
    _remap_buses!(jpc, e2i, T)

Apply the external→internal bus mapping `e2i` to all bus-referenced columns
in `jpc`. Uses schema-defined column names for correctness.
"""
function _remap_buses!(jpc::PowerCaseData{K, T}, e2i, ::Type{T}) where {K, T}
    # Bus IDs
    for i in 1:nrows(jpc.bus)
        jpc.bus[i, :I] = T(e2i[Int(jpc.bus[i, :I])])
    end
    # Branch
    for i in 1:nrows(jpc.branch)
        jpc.branch[i, :F_BUS] = T(e2i[Int(jpc.branch[i, :F_BUS])])
        jpc.branch[i, :T_BUS] = T(e2i[Int(jpc.branch[i, :T_BUS])])
    end
    # Generator
    for i in 1:nrows(jpc.gen)
        jpc.gen[i, :GEN_BUS] = T(e2i[Int(jpc.gen[i, :GEN_BUS])])
    end
    # Load
    for i in 1:nrows(jpc.load)
        jpc.load[i, :LOAD_BUS] = T(e2i[Int(jpc.load[i, :LOAD_BUS])])
    end
    # Storage
    for i in 1:nrows(jpc.storage)
        jpc.storage[i, :STOR_BUS] = T(e2i[Int(jpc.storage[i, :STOR_BUS])])
    end
    # Shunt (ShuntSchema: BUS is column 1)
    for i in 1:nrows(jpc.shunt)
        jpc.shunt[i, :BUS] = T(e2i[Int(jpc.shunt[i, :BUS])])
    end
    # Static Generator (SgenSchema: BUS is column 2, ID is column 1)
    for i in 1:nrows(jpc.sgen)
        jpc.sgen[i, :BUS] = T(e2i[Int(jpc.sgen[i, :BUS])])
    end
    # External Grid (ExtGridSchema: BUS is column 1)
    for i in 1:nrows(jpc.ext_grid)
        jpc.ext_grid[i, :BUS] = T(e2i[Int(jpc.ext_grid[i, :BUS])])
    end
    # Converter (ConverterSchema: ACBUS, DCBUS)
    for i in 1:nrows(jpc.converter)
        jpc.converter[i, :ACBUS] = T(e2i[Int(jpc.converter[i, :ACBUS])])
        jpc.converter[i, :DCBUS] = T(e2i[Int(jpc.converter[i, :DCBUS])])
    end
    # DCDC Converter (DCDCSchema: BUS_IN, BUS_OUT)
    for i in 1:nrows(jpc.dcdc)
        jpc.dcdc[i, :BUS_IN] = T(e2i[Int(jpc.dcdc[i, :BUS_IN])])
        jpc.dcdc[i, :BUS_OUT] = T(e2i[Int(jpc.dcdc[i, :BUS_OUT])])
    end
    # Switch (SwitchSchema: BUS_FROM, BUS_TO)
    for i in 1:nrows(jpc.switch)
        jpc.switch[i, :BUS_FROM] = T(e2i[Int(jpc.switch[i, :BUS_FROM])])
        jpc.switch[i, :BUS_TO] = T(e2i[Int(jpc.switch[i, :BUS_TO])])
    end
    # Transformer 2W (Trafo2WSchema: HV_BUS, LV_BUS)
    for i in 1:nrows(jpc.trafo)
        jpc.trafo[i, :HV_BUS] = T(e2i[Int(jpc.trafo[i, :HV_BUS])])
        jpc.trafo[i, :LV_BUS] = T(e2i[Int(jpc.trafo[i, :LV_BUS])])
    end
    # Transformer 3W (Trafo3WSchema: HV_BUS, MV_BUS, LV_BUS)
    for i in 1:nrows(jpc.trafo3w)
        jpc.trafo3w[i, :HV_BUS] = T(e2i[Int(jpc.trafo3w[i, :HV_BUS])])
        jpc.trafo3w[i, :MV_BUS] = T(e2i[Int(jpc.trafo3w[i, :MV_BUS])])
        jpc.trafo3w[i, :LV_BUS] = T(e2i[Int(jpc.trafo3w[i, :LV_BUS])])
    end
    # Energy Router Port (ERPortSchema: BUS)
    for i in 1:nrows(jpc.er_port)
        jpc.er_port[i, :BUS] = T(e2i[Int(jpc.er_port[i, :BUS])])
    end
end


# ── Helper: remove out-of-service rows ────────────────────────────────────────

function _filter_oos!(jpc::PowerCaseData{K, T}) where {K, T}
    # Buses: type ≠ 0 (ISOLATED allowed, type 0 = removed)
    _keep_rows!(jpc, :bus,     i -> jpc.bus[i, :TYPE] != T(0))
    # Branches: STATUS ≠ 0
    _keep_rows!(jpc, :branch,  i -> jpc.branch[i, :STATUS] != T(0))
    # Generators: GEN_STATUS ≠ 0
    _keep_rows!(jpc, :gen,     i -> jpc.gen[i, :GEN_STATUS] != T(0))
    # Loads: LOAD_STATUS ≠ 0
    _keep_rows!(jpc, :load,    i -> jpc.load[i, :LOAD_STATUS] != T(0))
end

"""
    _keep_rows!(jpc, field, predicate)

In-place filter: keep only rows where `predicate(row_index)` is true.
"""
function _keep_rows!(jpc::PowerCaseData{K, T}, field::Symbol, pred) where {K, T}
    mat = getfield(jpc, field)
    nr = nrows(mat)
    nr == 0 && return
    keep = [i for i in 1:nr if pred(i)]
    length(keep) == nr && return  # nothing filtered

    # Rebuild component matrix with kept rows
    data = rawdata(mat)
    new_data = data[keep, :]
    S = schema_type(mat)
    new_mat = ComponentMatrix{S, T}(new_data)
    setfield!(jpc, field, new_mat)
end
