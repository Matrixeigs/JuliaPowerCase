# ═══════════════════════════════════════════════════════════════════════════════
# PowerCaseData — Matrix-based Container (MATPOWER-style)
# ═══════════════════════════════════════════════════════════════════════════════

"""
    PowerCaseData{K<:SystemKind, T<:Real}

Matrix-based power system container using [`ComponentMatrix`](@ref).
Each table (bus, branch, gen, …) is a `ComponentMatrix` with schema-driven
column indexing, giving MATPOWER-compatible flat storage when `T=Float64`.

# Example
```julia
jpc = PowerCaseData{AC, Float64}()
jpc.bus[1, :VM] = 1.02
```
"""
@kwdef mutable struct PowerCaseData{K<:SystemKind, T<:Real}
    bus::ComponentMatrix{BusSchema, T}             = ComponentMatrix{BusSchema, T}(0)
    branch::ComponentMatrix{BranchSchema, T}       = ComponentMatrix{BranchSchema, T}(0)
    gen::ComponentMatrix{GenSchema, T}             = ComponentMatrix{GenSchema, T}(0)
    gencost::ComponentMatrix{GenCostSchema, T}     = ComponentMatrix{GenCostSchema, T}(0)
    load::ComponentMatrix{LoadSchema, T}           = ComponentMatrix{LoadSchema, T}(0)
    sgen::ComponentMatrix{SgenSchema, T}           = ComponentMatrix{SgenSchema, T}(0)
    ext_grid::ComponentMatrix{ExtGridSchema, T}    = ComponentMatrix{ExtGridSchema, T}(0)
    storage::ComponentMatrix{StorageSchema, T}     = ComponentMatrix{StorageSchema, T}(0)
    switch::ComponentMatrix{SwitchSchema, T}       = ComponentMatrix{SwitchSchema, T}(0)
    shunt::ComponentMatrix{ShuntSchema, T}         = ComponentMatrix{ShuntSchema, T}(0)
    trafo::ComponentMatrix{Trafo2WSchema, T}       = ComponentMatrix{Trafo2WSchema, T}(0)
    trafo3w::ComponentMatrix{Trafo3WSchema, T}     = ComponentMatrix{Trafo3WSchema, T}(0)
    converter::ComponentMatrix{ConverterSchema, T} = ComponentMatrix{ConverterSchema, T}(0)
    dcdc::ComponentMatrix{DCDCSchema, T}           = ComponentMatrix{DCDCSchema, T}(0)
    energy_router::ComponentMatrix{ERSchema, T}    = ComponentMatrix{ERSchema, T}(0)
    er_port::ComponentMatrix{ERPortSchema, T}      = ComponentMatrix{ERPortSchema, T}(0)
    # System parameters
    name::String                                   = ""
    base_mva::T                                    = T(100)
    base_kv::T                                     = T(110)
    freq_hz::T                                     = T(50)
    version::String                                = "1.0"
    # Component names sidecar: (component_type, index) -> name
    # Currently supports converter types only: :vsc, :dcdc, :energy_router, :er_port
    # (These types have `name::String` fields that cannot be stored in numeric matrices)
    component_names::Dict{Tuple{Symbol, Int}, String} = Dict{Tuple{Symbol, Int}, String}()
end

const ACPowerCaseData{T} = PowerCaseData{AC, T}
const DCPowerCaseData{T} = PowerCaseData{DC, T}


"""
    HybridPowerCaseData{T<:Real}

Matrix-based hybrid AC/DC container linking two `PowerCaseData` with converter tables.
"""
@kwdef mutable struct HybridPowerCaseData{T<:Real}
    ac::PowerCaseData{AC, T}                          = PowerCaseData{AC, T}()
    dc::PowerCaseData{DC, T}                          = PowerCaseData{DC, T}()
    dc_bus::ComponentMatrix{DCBusSchema, T}           = ComponentMatrix{DCBusSchema, T}(0)
    dc_branch::ComponentMatrix{DCBranchSchema, T}     = ComponentMatrix{DCBranchSchema, T}(0)
    vsc::ComponentMatrix{VSCSchema, T}                = ComponentMatrix{VSCSchema, T}(0)
    er_core::ComponentMatrix{EnergyRouterCoreSchema, T} = ComponentMatrix{EnergyRouterCoreSchema, T}(0)
    er_conv::ComponentMatrix{EnergyRouterConvSchema, T} = ComponentMatrix{EnergyRouterConvSchema, T}(0)
    name::String                                      = ""
    base_mva::T                                       = T(100)
    version::String                                   = "1.0"
end


# ── Element Counts ────────────────────────────────────────────────────────────

nbuses(jpc::PowerCaseData)      = nrows(jpc.bus)
nbranches(jpc::PowerCaseData)   = nrows(jpc.branch)
ngenerators(jpc::PowerCaseData) = nrows(jpc.gen)
nloads(jpc::PowerCaseData)      = nrows(jpc.load)
nstorage(jpc::PowerCaseData)    = nrows(jpc.storage)

"""Count all converters (VSC + DCDC + EnergyRouter)."""
nconverters(jpc::PowerCaseData) = nrows(jpc.converter) + nrows(jpc.dcdc) + nrows(jpc.energy_router)

"""Count VSC converters only."""
nvsc_converters(jpc::PowerCaseData) = nrows(jpc.converter)

"""Count DCDC converters."""
ndcdc_converters(jpc::PowerCaseData) = nrows(jpc.dcdc)

"""Count energy routers."""
nenergy_routers(jpc::PowerCaseData) = nrows(jpc.energy_router)

"""
    valid_buses(jpc::PowerCaseData) -> Vector{Int}

Return bus indices with TYPE ≠ 0 (not removed from network).
Includes ISOLATED_BUS (TYPE=4) since it's a valid bus type.
Used by ext2int for renumbering.
"""
function valid_buses(jpc::PowerCaseData{K, T}) where {K, T}
    [Int(jpc.bus[i, :I]) for i in 1:nbuses(jpc) if jpc.bus[i, :TYPE] != T(0)]
end

"""
    active_buses(jpc::PowerCaseData) -> Vector{Int}

Return bus indices that are energized (TYPE ∈ {1,2,3}, excludes ISOLATED_BUS=4).
For topology analysis of the connected network.
"""
function active_buses(jpc::PowerCaseData{K, T}) where {K, T}
    [Int(jpc.bus[i, :I]) for i in 1:nbuses(jpc) if jpc.bus[i, :TYPE] ∈ (T(1), T(2), T(3))]
end

"""In-service branch indices (STATUS ≠ 0)."""
function active_branches(jpc::PowerCaseData{K, T}) where {K, T}
    [i for i in 1:nbranches(jpc) if jpc.branch[i, :STATUS] != T(0)]
end


# ── Pretty Printing ──────────────────────────────────────────────────────────

function Base.show(io::IO, jpc::PowerCaseData{K, T}) where {K, T}
    print(io, "PowerCaseData{$K,$T}($(nbuses(jpc)) buses, $(nbranches(jpc)) branches, $(ngenerators(jpc)) gens)")
end

function Base.show(io::IO, ::MIME"text/plain", jpc::PowerCaseData{K, T}) where {K, T}
    println(io, "PowerCaseData{$K, $T}: \"$(jpc.name)\"")
    println(io, "  Base MVA: $(jpc.base_mva)")
    println(io, "  Frequency: $(jpc.freq_hz) Hz")
    println(io, "  ──────────────────")
    println(io, "  Bus:         $(nbuses(jpc))")
    println(io, "  Branch:      $(nbranches(jpc))")
    println(io, "  Gen:         $(ngenerators(jpc))")
    println(io, "  Load:        $(nloads(jpc))")
    println(io, "  Storage:     $(nstorage(jpc))")
    println(io, "  Converter:   $(nconverters(jpc))")
    println(io, "  Shunt:       $(nrows(jpc.shunt))")
    println(io, "  Switch:      $(nrows(jpc.switch))")
    println(io, "  Trafo (2W):  $(nrows(jpc.trafo))")
    println(io, "  Trafo (3W):  $(nrows(jpc.trafo3w))")
end

function Base.show(io::IO, h::HybridPowerCaseData{T}) where T
    print(io, "HybridPowerCaseData{$T}(AC: $(nbuses(h.ac)) buses, DC: $(nrows(h.dc_bus)) buses, VSC: $(nrows(h.vsc)))")
end


# ── Equality Comparison ──────────────────────────────────────────────────────

"""
    Base.==(a::PowerCaseData{K,T}, b::PowerCaseData{K,T}) -> Bool

Compare two PowerCaseData instances for structural equality.
Compares all ComponentMatrix data and metadata fields.
"""
function Base.:(==)(a::PowerCaseData{K,T}, b::PowerCaseData{K,T}) where {K,T}
    a.name == b.name &&
    a.base_mva == b.base_mva &&
    a.base_kv == b.base_kv &&
    a.freq_hz == b.freq_hz &&
    a.version == b.version &&
    rawdata(a.bus) == rawdata(b.bus) &&
    rawdata(a.branch) == rawdata(b.branch) &&
    rawdata(a.gen) == rawdata(b.gen) &&
    rawdata(a.load) == rawdata(b.load) &&
    rawdata(a.storage) == rawdata(b.storage) &&
    rawdata(a.sgen) == rawdata(b.sgen) &&
    rawdata(a.ext_grid) == rawdata(b.ext_grid) &&
    rawdata(a.switch) == rawdata(b.switch) &&
    rawdata(a.converter) == rawdata(b.converter) &&
    rawdata(a.dcdc) == rawdata(b.dcdc) &&
    rawdata(a.energy_router) == rawdata(b.energy_router) &&
    rawdata(a.er_port) == rawdata(b.er_port) &&
    a.component_names == b.component_names
end

"""
    Base.==(a::HybridPowerCaseData{T}, b::HybridPowerCaseData{T}) -> Bool

Compare two HybridPowerCaseData instances for structural equality.
"""
function Base.:(==)(a::HybridPowerCaseData{T}, b::HybridPowerCaseData{T}) where T
    a.name == b.name &&
    a.base_mva == b.base_mva &&
    a.version == b.version &&
    a.ac == b.ac &&
    a.dc == b.dc &&
    rawdata(a.dc_bus) == rawdata(b.dc_bus) &&
    rawdata(a.dc_branch) == rawdata(b.dc_branch) &&
    rawdata(a.vsc) == rawdata(b.vsc)
end


# ── Copy Operations ──────────────────────────────────────────────────────────

"""Helper to copy a ComponentMatrix."""
function _copy_component_matrix(cm::ComponentMatrix{S,T}) where {S,T}
    n = nrows(cm)
    result = ComponentMatrix{S,T}(n)
    if n > 0
        rawdata(result) .= rawdata(cm)
    end
    return result
end

"""
    Base.copy(jpc::PowerCaseData{K,T}) -> PowerCaseData{K,T}

Create a shallow copy of a PowerCaseData. ComponentMatrix data is copied.
"""
function Base.copy(jpc::PowerCaseData{K,T}) where {K,T}
    PowerCaseData{K,T}(
        bus = _copy_component_matrix(jpc.bus),
        branch = _copy_component_matrix(jpc.branch),
        gen = _copy_component_matrix(jpc.gen),
        gencost = _copy_component_matrix(jpc.gencost),
        load = _copy_component_matrix(jpc.load),
        sgen = _copy_component_matrix(jpc.sgen),
        ext_grid = _copy_component_matrix(jpc.ext_grid),
        storage = _copy_component_matrix(jpc.storage),
        switch = _copy_component_matrix(jpc.switch),
        shunt = _copy_component_matrix(jpc.shunt),
        trafo = _copy_component_matrix(jpc.trafo),
        trafo3w = _copy_component_matrix(jpc.trafo3w),
        converter = _copy_component_matrix(jpc.converter),
        dcdc = _copy_component_matrix(jpc.dcdc),
        energy_router = _copy_component_matrix(jpc.energy_router),
        er_port = _copy_component_matrix(jpc.er_port),
        name = jpc.name,
        base_mva = jpc.base_mva,
        base_kv = jpc.base_kv,
        freq_hz = jpc.freq_hz,
        version = jpc.version,
        component_names = copy(jpc.component_names),
    )
end

"""
    Base.deepcopy(jpc::PowerCaseData{K,T}) -> PowerCaseData{K,T}

Create a deep copy of a PowerCaseData. All data is recursively copied.
"""
Base.deepcopy(jpc::PowerCaseData{K,T}) where {K,T} = copy(jpc)  # copy already creates independent data

"""
    Base.copy(h::HybridPowerCaseData{T}) -> HybridPowerCaseData{T}

Create a shallow copy of a HybridPowerCaseData.
"""
function Base.copy(h::HybridPowerCaseData{T}) where T
    HybridPowerCaseData{T}(
        ac = copy(h.ac),
        dc = copy(h.dc),
        dc_bus = _copy_component_matrix(h.dc_bus),
        dc_branch = _copy_component_matrix(h.dc_branch),
        vsc = _copy_component_matrix(h.vsc),
        name = h.name,
        base_mva = h.base_mva,
        version = h.version,
    )
end

"""
    Base.deepcopy(h::HybridPowerCaseData{T}) -> HybridPowerCaseData{T}

Create a deep copy of a HybridPowerCaseData.
"""
Base.deepcopy(h::HybridPowerCaseData{T}) where T = copy(h)
