# ═══════════════════════════════════════════════════════════════════════════════
# Island Extraction — Split system into per-island PowerCaseData
# ═══════════════════════════════════════════════════════════════════════════════

"""
    extract_islands(jpc::PowerCaseData{AC,T}) -> Vector{PowerCaseData{AC,T}}

Split a power system into electrically connected sub-systems (islands).
Only islands with at least one power source (PV/REF bus, online generator,
storage, or external grid) are returned; buses in source-less islands are
reported via `@warn`.
"""
function extract_islands(jpc::PowerCaseData{AC, T}) where T
    groups, _ = find_islands(jpc)
    isempty(groups) && return PowerCaseData{AC,T}[]

    # Pre-compute lookup helpers
    nb = nrows(jpc.bus)
    ng = nrows(jpc.gen)
    nl = nrows(jpc.branch)
    nld = nrows(jpc.load)
    ns = nrows(jpc.storage)

    e2i = Dict{Int, Int}()
    for i in 1:nb
        e2i[Int(jpc.bus[i, :I])] = i
    end
    gen_bus  = [Int(jpc.gen[j, :GEN_BUS]) for j in 1:ng]
    gen_stat = [jpc.gen[j, :GEN_STATUS]   for j in 1:ng]
    br_f     = [Int(jpc.branch[j, :F_BUS]) for j in 1:nl]
    br_t     = [Int(jpc.branch[j, :T_BUS]) for j in 1:nl]

    islands = PowerCaseData{AC, T}[]

    for group in groups
        bset = Set(group)

        # ── Power-source check ────────────────────────────────────────────
        has_source = false
        for bus_id in group
            row = get(e2i, bus_id, 0)
            row == 0 && continue
            bt = Int(jpc.bus[row, :TYPE])
            if bt == Int(PV_BUS) || bt == Int(REF_BUS)
                has_source = true; break
            end
        end
        if !has_source
            for j in 1:ng
                if gen_bus[j] ∈ bset && gen_stat[j] != T(0)
                    has_source = true; break
                end
            end
        end
        if !has_source
            for j in 1:ns
                if Int(jpc.storage[j, :STOR_BUS]) ∈ bset
                    has_source = true; break
                end
            end
        end
        if !has_source
            @warn "Island with buses $(first(group, 5))… has no power source — skipped"
            continue
        end

        # ── Build sub-system ──────────────────────────────────────────────
        sub = PowerCaseData{AC, T}()
        sub.base_mva = jpc.base_mva
        sub.base_kv  = jpc.base_kv
        sub.freq_hz  = jpc.freq_hz

        # Buses
        bus_rows = [e2i[id] for id in group if haskey(e2i, id)]
        sub.bus = ComponentMatrix{BusSchema, T}(length(bus_rows))
        for (j, r) in enumerate(bus_rows)
            rawdata(sub.bus)[j, :] .= rawdata(jpc.bus)[r, :]
        end

        # Branches
        ibr = [j for j in 1:nl if br_f[j] ∈ bset && br_t[j] ∈ bset]
        if !isempty(ibr)
            sub.branch = ComponentMatrix{BranchSchema, T}(length(ibr))
            for (k, j) in enumerate(ibr)
                rawdata(sub.branch)[k, :] .= rawdata(jpc.branch)[j, :]
            end
        end

        # Generators
        ig = [j for j in 1:ng if gen_bus[j] ∈ bset]
        if !isempty(ig)
            sub.gen = ComponentMatrix{GenSchema, T}(length(ig))
            for (k, j) in enumerate(ig)
                rawdata(sub.gen)[k, :] .= rawdata(jpc.gen)[j, :]
            end
        end

        # Loads
        ild = [j for j in 1:nld if Int(jpc.load[j, :LOAD_BUS]) ∈ bset]
        if !isempty(ild)
            sub.load = ComponentMatrix{LoadSchema, T}(length(ild))
            for (k, j) in enumerate(ild)
                rawdata(sub.load)[k, :] .= rawdata(jpc.load)[j, :]
            end
        end

        # Storage
        ist = [j for j in 1:ns if Int(jpc.storage[j, :STOR_BUS]) ∈ bset]
        if !isempty(ist)
            sub.storage = ComponentMatrix{StorageSchema, T}(length(ist))
            for (k, j) in enumerate(ist)
                rawdata(sub.storage)[k, :] .= rawdata(jpc.storage)[j, :]
            end
        end

        push!(islands, sub)
    end

    return islands
end
