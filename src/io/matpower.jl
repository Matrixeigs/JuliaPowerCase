# ═══════════════════════════════════════════════════════════════════════════════
# MATPOWER .m File Import
# ═══════════════════════════════════════════════════════════════════════════════

"""
    load_matpower(filepath::String; T=Float64) -> PowerCaseData{AC,T}

Parse a MATPOWER `.m` case file into a `PowerCaseData{AC}`.

Supports standard MATPOWER fields: `mpc.bus`, `mpc.gen`, `mpc.branch`,
`mpc.gencost`, and `mpc.baseMVA`.
"""
function load_matpower(filepath::String; T::Type{<:Real}=Float64)
    !isfile(filepath) && throw(ArgumentError("File not found: $filepath"))
    text = read(filepath, String)

    jpc = PowerCaseData{AC, T}()

    # ── baseMVA ───────────────────────────────────────────────────────────
    m = match(r"mpc\.baseMVA\s*=\s*([0-9.]+)", text)
    if m !== nothing
        jpc.base_mva = parse(T, m.captures[1])
    end

    # ── Parse matrices ────────────────────────────────────────────────────
    bus_data    = _parse_matpower_matrix(text, "bus", T)
    gen_data    = _parse_matpower_matrix(text, "gen", T)
    branch_data = _parse_matpower_matrix(text, "branch", T)
    gencost_data = _parse_matpower_matrix(text, "gencost", T)

    if bus_data !== nothing
        jpc.bus = ComponentMatrix{BusSchema, T}(bus_data)
    end
    if gen_data !== nothing
        jpc.gen = ComponentMatrix{GenSchema, T}(gen_data)
    end
    if branch_data !== nothing
        jpc.branch = ComponentMatrix{BranchSchema, T}(branch_data)
    end
    if gencost_data !== nothing
        jpc.gencost = ComponentMatrix{GenCostSchema, T}(gencost_data)
    end

    return jpc
end


"""
    _parse_matpower_matrix(text, name, T) -> Union{Matrix{T}, Nothing}

Extract a matrix definition `mpc.<name> = [ ... ];` from MATPOWER text.
"""
function _parse_matpower_matrix(text::String, name::String, T::Type{<:Real})
    pattern = Regex("mpc\\.$name\\s*=\\s*\\[([^\\]]+)\\]", "s")
    m = match(pattern, text)
    m === nothing && return nothing

    raw = m.captures[1]
    rows = T[]
    ncols = 0
    for line in split(raw, '\n')
        line = strip(replace(line, r"[;%].*" => ""))
        isempty(line) && continue
        vals = [parse(T, s) for s in split(line) if !isempty(s)]
        isempty(vals) && continue
        if ncols == 0
            ncols = length(vals)
        end
        append!(rows, vals)
    end

    ncols == 0 && return nothing
    nrows_parsed = div(length(rows), ncols)
    return reshape(rows, ncols, nrows_parsed)' |> collect
end
