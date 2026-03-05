# ═══════════════════════════════════════════════════════════════════════════════
# Internal → External Numbering  (int2ext)
# ═══════════════════════════════════════════════════════════════════════════════

"""
    int2ext(jpc::PowerCaseData{K,T}, i2e::Vector{Int}) -> PowerCaseData{K,T}

Restore original external bus numbering from an internally-numbered system.

`i2e` is the mapping produced by [`ext2int`](@ref):
`i2e[internal_index] → external_bus_number`.
"""
function int2ext(jpc::PowerCaseData{K, T}, i2e::Vector{Int}) where {K, T}
    out = deepcopy(jpc)
    isempty(i2e) && return out

    # Bus IDs
    for i in 1:nrows(out.bus)
        idx = Int(out.bus[i, :I])
        out.bus[i, :I] = T(i2e[idx])
    end
    # Branch
    for i in 1:nrows(out.branch)
        out.branch[i, :F_BUS] = T(i2e[Int(out.branch[i, :F_BUS])])
        out.branch[i, :T_BUS] = T(i2e[Int(out.branch[i, :T_BUS])])
    end
    # Generator
    for i in 1:nrows(out.gen)
        out.gen[i, :GEN_BUS] = T(i2e[Int(out.gen[i, :GEN_BUS])])
    end
    # Load
    for i in 1:nrows(out.load)
        out.load[i, :LOAD_BUS] = T(i2e[Int(out.load[i, :LOAD_BUS])])
    end
    # Storage
    for i in 1:nrows(out.storage)
        out.storage[i, :STOR_BUS] = T(i2e[Int(out.storage[i, :STOR_BUS])])
    end
    # Shunt (ShuntSchema: BUS)
    for i in 1:nrows(out.shunt)
        out.shunt[i, :BUS] = T(i2e[Int(out.shunt[i, :BUS])])
    end
    # Static Generator (SgenSchema: BUS is column 2)
    for i in 1:nrows(out.sgen)
        out.sgen[i, :BUS] = T(i2e[Int(out.sgen[i, :BUS])])
    end
    # External Grid (ExtGridSchema: BUS)
    for i in 1:nrows(out.ext_grid)
        out.ext_grid[i, :BUS] = T(i2e[Int(out.ext_grid[i, :BUS])])
    end
    # Converter (ConverterSchema: ACBUS, DCBUS)
    for i in 1:nrows(out.converter)
        out.converter[i, :ACBUS] = T(i2e[Int(out.converter[i, :ACBUS])])
        out.converter[i, :DCBUS] = T(i2e[Int(out.converter[i, :DCBUS])])
    end
    # DCDC Converter (DCDCSchema: BUS_IN, BUS_OUT)
    for i in 1:nrows(out.dcdc)
        out.dcdc[i, :BUS_IN] = T(i2e[Int(out.dcdc[i, :BUS_IN])])
        out.dcdc[i, :BUS_OUT] = T(i2e[Int(out.dcdc[i, :BUS_OUT])])
    end
    # Switch (SwitchSchema: BUS_FROM, BUS_TO)
    for i in 1:nrows(out.switch)
        out.switch[i, :BUS_FROM] = T(i2e[Int(out.switch[i, :BUS_FROM])])
        out.switch[i, :BUS_TO] = T(i2e[Int(out.switch[i, :BUS_TO])])
    end
    # Transformer 2W (Trafo2WSchema: HV_BUS, LV_BUS)
    for i in 1:nrows(out.trafo)
        out.trafo[i, :HV_BUS] = T(i2e[Int(out.trafo[i, :HV_BUS])])
        out.trafo[i, :LV_BUS] = T(i2e[Int(out.trafo[i, :LV_BUS])])
    end
    # Transformer 3W (Trafo3WSchema: HV_BUS, MV_BUS, LV_BUS)
    for i in 1:nrows(out.trafo3w)
        out.trafo3w[i, :HV_BUS] = T(i2e[Int(out.trafo3w[i, :HV_BUS])])
        out.trafo3w[i, :MV_BUS] = T(i2e[Int(out.trafo3w[i, :MV_BUS])])
        out.trafo3w[i, :LV_BUS] = T(i2e[Int(out.trafo3w[i, :LV_BUS])])
    end
    # Energy Router Port (ERPortSchema: BUS)
    for i in 1:nrows(out.er_port)
        out.er_port[i, :BUS] = T(i2e[Int(out.er_port[i, :BUS])])
    end

    return out
end

"""
    renumber!(jpc::PowerCaseData{K,T}) -> (jpc, i2e)

In-place version: renumber buses to 1:nb and return the mapping.
Equivalent to `ext2int` but mutates the input (without OOS filtering).
"""
function renumber!(jpc::PowerCaseData{K, T}) where {K, T}
    nb = nrows(jpc.bus)
    nb == 0 && return jpc, Int[]

    i2e = [Int(jpc.bus[i, :I]) for i in 1:nb]
    max_bus = maximum(i2e)
    e2i = sparsevec(i2e, collect(1:nb), max_bus)

    # Reuse the centralized remap helper
    _remap_buses!(jpc, e2i, T)

    return jpc, i2e
end
