# ═══════════════════════════════════════════════════════════════════════════════
# ETAP Import — CSV/XML Import from ETAP Power System Analysis Tool
# ═══════════════════════════════════════════════════════════════════════════════
#
# ETAP is a commercial power system analysis tool. This file provides
# functions for converting ETAP CSV exports into JuliaPowerCase structures.
# Supports ETAP 21.x and later CSV export formats.

"""
    load_etap_csv(dirpath::String; T=Float64, version=:v21) -> PowerCaseData{AC,T}

Import ETAP CSV bus/branch/gen/load exports from `dirpath`.

# Arguments
- `dirpath`: Directory containing ETAP CSV exports
- `T`: Numeric type for matrix storage (default: Float64)
- `version`: ETAP version hint (`:v21`, `:v22` supported)

# Expected Files
- `Bus.csv` — Bus data with columns: ID, Name, kV, Type, Vm, Va, Pd, Qd, Gs, Bs
- `Branch.csv` — Branch data with columns: ID, FromBus, ToBus, R, X, B, RateA
- `Generator.csv` — Generator data with columns: ID, Bus, Pg, Qg, Pmax, Pmin
- `Load.csv` — Load data with columns: ID, Bus, Pd, Qd

# Example
```julia
jpc = load_etap_csv("/path/to/etap_export/")
println("Loaded \$(nbuses(jpc)) buses, \$(nbranches(jpc)) branches")
```
"""
function load_etap_csv(dirpath::String; T::Type{<:Real}=Float64, version::Symbol=:v21)
    !isdir(dirpath) && throw(ArgumentError("Directory not found: $dirpath"))
    
    jpc = PowerCaseData{AC, T}()
    jpc.name = "ETAP Import: $(basename(dirpath))"
    
    # ── Load Bus.csv ──────────────────────────────────────────────────────
    bus_file = joinpath(dirpath, "Bus.csv")
    if isfile(bus_file)
        jpc.bus = _load_etap_bus_csv(bus_file, T, version)
    end
    
    # ── Load Branch.csv ───────────────────────────────────────────────────
    branch_file = joinpath(dirpath, "Branch.csv")
    if isfile(branch_file)
        jpc.branch = _load_etap_branch_csv(branch_file, T, version)
    end
    
    # ── Load Generator.csv ────────────────────────────────────────────────
    gen_file = joinpath(dirpath, "Generator.csv")
    if isfile(gen_file)
        jpc.gen = _load_etap_gen_csv(gen_file, T, version)
    end
    
    # ── Load Load.csv ─────────────────────────────────────────────────────
    load_file = joinpath(dirpath, "Load.csv")
    if isfile(load_file)
        jpc.load = _load_etap_load_csv(load_file, T, version)
    end
    
    # ── Load Storage.csv (optional) ───────────────────────────────────────
    storage_file = joinpath(dirpath, "Storage.csv")
    if isfile(storage_file)
        jpc.storage = _load_etap_storage_csv(storage_file, T, version)
    end
    
    return jpc
end

"""
    _load_etap_bus_csv(filepath, T, version) -> ComponentMatrix{BusSchema,T}

Parse ETAP Bus.csv file.
"""
function _load_etap_bus_csv(filepath::String, T::Type{<:Real}, version::Symbol)
    lines = readlines(filepath)
    isempty(lines) && return ComponentMatrix{BusSchema, T}(0)
    
    # Parse header to find column indices
    header = lowercase.(strip.(split(lines[1], ',')))
    col_map = Dict{String, Int}(col => i for (i, col) in enumerate(header))
    
    # Standard ETAP column mappings
    id_col = get(col_map, "id", get(col_map, "bus_id", 1))
    kv_col = get(col_map, "kv", get(col_map, "base_kv", 0))
    type_col = get(col_map, "type", get(col_map, "bus_type", 0))
    vm_col = get(col_map, "vm", get(col_map, "voltage", 0))
    va_col = get(col_map, "va", get(col_map, "angle", 0))
    pd_col = get(col_map, "pd", get(col_map, "p_load", 0))
    qd_col = get(col_map, "qd", get(col_map, "q_load", 0))
    gs_col = get(col_map, "gs", 0)
    bs_col = get(col_map, "bs", 0)
    vmax_col = get(col_map, "vmax", 0)
    vmin_col = get(col_map, "vmin", 0)
    
    # Filter non-empty data lines first
    data_lines = filter(l -> !isempty(strip(split(l, ',')[1])), lines[2:end])
    nbus = length(data_lines)
    nbus == 0 && return ComponentMatrix{BusSchema, T}(0)
    
    bus_mat = ComponentMatrix{BusSchema, T}(nbus)
    
    for (i, line) in enumerate(data_lines)
        fields = strip.(split(line, ','))
        
        bus_mat[i, :I] = _parse_field(T, fields, id_col, T(i))
        bus_mat[i, :TYPE] = _parse_field(T, fields, type_col, T(1))
        bus_mat[i, :PD] = _parse_field(T, fields, pd_col, T(0))
        bus_mat[i, :QD] = _parse_field(T, fields, qd_col, T(0))
        bus_mat[i, :GS] = _parse_field(T, fields, gs_col, T(0))
        bus_mat[i, :BS] = _parse_field(T, fields, bs_col, T(0))
        bus_mat[i, :AREA] = T(1)
        bus_mat[i, :VM] = _parse_field(T, fields, vm_col, T(1))
        bus_mat[i, :VA] = _parse_field(T, fields, va_col, T(0))
        bus_mat[i, :BASE_KV] = _parse_field(T, fields, kv_col, T(1))
        bus_mat[i, :ZONE] = T(1)
        bus_mat[i, :VMAX] = _parse_field(T, fields, vmax_col, T(1.1))
        bus_mat[i, :VMIN] = _parse_field(T, fields, vmin_col, T(0.9))
    end
    
    return bus_mat
end

"""
    _load_etap_branch_csv(filepath, T, version) -> ComponentMatrix{BranchSchema,T}

Parse ETAP Branch.csv file.
"""
function _load_etap_branch_csv(filepath::String, T::Type{<:Real}, version::Symbol)
    lines = readlines(filepath)
    isempty(lines) && return ComponentMatrix{BranchSchema, T}(0)
    
    header = lowercase.(strip.(split(lines[1], ',')))
    col_map = Dict{String, Int}(col => i for (i, col) in enumerate(header))
    
    # Standard mappings
    id_col = get(col_map, "id", get(col_map, "branch_id", 1))
    fbus_col = get(col_map, "frombus", get(col_map, "from_bus", get(col_map, "f_bus", 0)))
    tbus_col = get(col_map, "tobus", get(col_map, "to_bus", get(col_map, "t_bus", 0)))
    r_col = get(col_map, "r", get(col_map, "r_pu", 0))
    x_col = get(col_map, "x", get(col_map, "x_pu", 0))
    b_col = get(col_map, "b", get(col_map, "b_pu", 0))
    rate_col = get(col_map, "ratea", get(col_map, "rate_a", get(col_map, "rating", 0)))
    
    # Filter non-empty data lines first
    data_lines = filter(l -> !isempty(strip(split(l, ',')[1])), lines[2:end])
    nbranch = length(data_lines)
    nbranch == 0 && return ComponentMatrix{BranchSchema, T}(0)
    
    branch_mat = ComponentMatrix{BranchSchema, T}(nbranch)
    
    for (i, line) in enumerate(data_lines)
        fields = strip.(split(line, ','))
        
        branch_mat[i, :INDEX] = _parse_field(T, fields, id_col, T(i))
        branch_mat[i, :F_BUS] = _parse_field(T, fields, fbus_col, T(0))
        branch_mat[i, :T_BUS] = _parse_field(T, fields, tbus_col, T(0))
        branch_mat[i, :R] = _parse_field(T, fields, r_col, T(0.01))
        branch_mat[i, :X] = _parse_field(T, fields, x_col, T(0.1))
        branch_mat[i, :B] = _parse_field(T, fields, b_col, T(0))
        branch_mat[i, :RATE_A] = _parse_field(T, fields, rate_col, T(9999))
        branch_mat[i, :RATE_B] = branch_mat[i, :RATE_A]
        branch_mat[i, :RATE_C] = branch_mat[i, :RATE_A]
        branch_mat[i, :TAP] = T(1)
        branch_mat[i, :SHIFT] = T(0)
        branch_mat[i, :STATUS] = T(1)
        branch_mat[i, :ANGMIN] = T(-360)
        branch_mat[i, :ANGMAX] = T(360)
    end
    
    return branch_mat
end

"""
    _load_etap_gen_csv(filepath, T, version) -> ComponentMatrix{GenSchema,T}

Parse ETAP Generator.csv file.
"""
function _load_etap_gen_csv(filepath::String, T::Type{<:Real}, version::Symbol)
    lines = readlines(filepath)
    isempty(lines) && return ComponentMatrix{GenSchema, T}(0)
    
    header = lowercase.(strip.(split(lines[1], ',')))
    col_map = Dict{String, Int}(col => i for (i, col) in enumerate(header))
    
    id_col = get(col_map, "id", get(col_map, "gen_id", 1))
    bus_col = get(col_map, "bus", get(col_map, "gen_bus", 0))
    pg_col = get(col_map, "pg", get(col_map, "p_mw", 0))
    qg_col = get(col_map, "qg", get(col_map, "q_mvar", 0))
    pmax_col = get(col_map, "pmax", 0)
    pmin_col = get(col_map, "pmin", 0)
    qmax_col = get(col_map, "qmax", 0)
    qmin_col = get(col_map, "qmin", 0)
    vg_col = get(col_map, "vg", get(col_map, "v_setpoint", 0))
    
    # Filter non-empty data lines first
    data_lines = filter(l -> !isempty(strip(split(l, ',')[1])), lines[2:end])
    ngen = length(data_lines)
    ngen == 0 && return ComponentMatrix{GenSchema, T}(0)
    
    gen_mat = ComponentMatrix{GenSchema, T}(ngen)
    
    for (i, line) in enumerate(data_lines)
        fields = strip.(split(line, ','))
        
        gen_mat[i, :INDEX] = _parse_field(T, fields, id_col, T(i))
        gen_mat[i, :GEN_BUS] = _parse_field(T, fields, bus_col, T(0))
        gen_mat[i, :PG] = _parse_field(T, fields, pg_col, T(0))
        gen_mat[i, :QG] = _parse_field(T, fields, qg_col, T(0))
        gen_mat[i, :QMAX] = _parse_field(T, fields, qmax_col, T(9999))
        gen_mat[i, :QMIN] = _parse_field(T, fields, qmin_col, T(-9999))
        gen_mat[i, :VG] = _parse_field(T, fields, vg_col, T(1))
        gen_mat[i, :MBASE] = T(100)
        gen_mat[i, :GEN_STATUS] = T(1)
        gen_mat[i, :PMAX] = _parse_field(T, fields, pmax_col, T(9999))
        gen_mat[i, :PMIN] = _parse_field(T, fields, pmin_col, T(0))
    end
    
    return gen_mat
end

"""
    _load_etap_load_csv(filepath, T, version) -> ComponentMatrix{LoadSchema,T}

Parse ETAP Load.csv file.
"""
function _load_etap_load_csv(filepath::String, T::Type{<:Real}, version::Symbol)
    lines = readlines(filepath)
    isempty(lines) && return ComponentMatrix{LoadSchema, T}(0)
    
    header = lowercase.(strip.(split(lines[1], ',')))
    col_map = Dict{String, Int}(col => i for (i, col) in enumerate(header))
    
    id_col = get(col_map, "id", get(col_map, "load_id", 1))
    bus_col = get(col_map, "bus", get(col_map, "load_bus", 0))
    pd_col = get(col_map, "pd", get(col_map, "p_mw", 0))
    qd_col = get(col_map, "qd", get(col_map, "q_mvar", 0))
    status_col = get(col_map, "status", get(col_map, "in_service", 0))
    
    # Filter non-empty data lines first
    data_lines = filter(l -> !isempty(strip(split(l, ',')[1])), lines[2:end])
    nload = length(data_lines)
    nload == 0 && return ComponentMatrix{LoadSchema, T}(0)
    
    load_mat = ComponentMatrix{LoadSchema, T}(nload)
    
    for (i, line) in enumerate(data_lines)
        fields = strip.(split(line, ','))
        
        load_mat[i, :INDEX] = _parse_field(T, fields, id_col, T(i))
        load_mat[i, :LOAD_BUS] = _parse_field(T, fields, bus_col, T(0))
        load_mat[i, :PD] = _parse_field(T, fields, pd_col, T(0))
        load_mat[i, :QD] = _parse_field(T, fields, qd_col, T(0))
        load_mat[i, :STATUS] = _parse_field(T, fields, status_col, T(1))
    end
    
    return load_mat
end

"""
    _load_etap_storage_csv(filepath, T, version) -> ComponentMatrix{StorageSchema,T}

Parse ETAP Storage.csv file.
"""
function _load_etap_storage_csv(filepath::String, T::Type{<:Real}, version::Symbol)
    lines = readlines(filepath)
    isempty(lines) && return ComponentMatrix{StorageSchema, T}(0)
    
    header = lowercase.(strip.(split(lines[1], ',')))
    col_map = Dict{String, Int}(col => i for (i, col) in enumerate(header))
    
    id_col = get(col_map, "id", 1)
    bus_col = get(col_map, "bus", 0)
    p_col = get(col_map, "p", get(col_map, "p_mw", 0))
    q_col = get(col_map, "q", get(col_map, "q_mvar", 0))
    e_col = get(col_map, "e", get(col_map, "e_mwh", 0))
    
    # Filter non-empty data lines first
    data_lines = filter(l -> !isempty(strip(split(l, ',')[1])), lines[2:end])
    nstor = length(data_lines)
    nstor == 0 && return ComponentMatrix{StorageSchema, T}(0)
    
    stor_mat = ComponentMatrix{StorageSchema, T}(nstor)
    
    for (i, line) in enumerate(data_lines)
        fields = strip.(split(line, ','))
        
        stor_mat[i, :INDEX] = _parse_field(T, fields, id_col, T(i))
        stor_mat[i, :STOR_BUS] = _parse_field(T, fields, bus_col, T(0))
        stor_mat[i, :STOR_P] = _parse_field(T, fields, p_col, T(0))
        stor_mat[i, :STOR_Q] = _parse_field(T, fields, q_col, T(0))
        stor_mat[i, :STOR_E_MWH] = _parse_field(T, fields, e_col, T(0))
        stor_mat[i, :STOR_STATUS] = T(1)
    end
    
    return stor_mat
end

"""Helper to safely parse a CSV field with default value."""
function _parse_field(::Type{T}, fields::Vector{SubString{String}}, col::Int, default::T) where T<:Real
    col <= 0 && return default
    col > length(fields) && return default
    val = strip(fields[col])
    isempty(val) && return default
    try
        return T(parse(Float64, val))
    catch
        return default
    end
end
