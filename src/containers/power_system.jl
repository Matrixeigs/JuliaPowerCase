# ═══════════════════════════════════════════════════════════════════════════════
# PowerSystem — Struct-based Container
# ═══════════════════════════════════════════════════════════════════════════════

"""
    PowerSystem{K<:SystemKind}

Type-safe container for power system components.
Parametric on [`AC`](@ref) or [`DC`](@ref).

# Example
```julia
sys = PowerSystem{AC}()
push!(sys.buses, Bus{AC}(index=1, name="Slack", bus_type=REF_BUS))
push!(sys.generators, Generator(index=1, bus=1, pg_mw=100.0))
```
"""
@kwdef mutable struct PowerSystem{K<:SystemKind}
    buses::Vector{Bus{K}}               = Bus{K}[]
    branches::Vector{Branch{K}}         = Branch{K}[]
    generators::Vector{Generator}       = Generator[]
    static_generators::Vector{StaticGenerator{K}} = StaticGenerator{K}[]
    loads::Vector{Load{K}}              = Load{K}[]
    storage::Vector{Storage{K}}         = Storage{K}[]
    # Converters (multiple types)
    converters::Vector{VSCConverter}    = VSCConverter[]      # Legacy alias for vsc_converters
    vsc_converters::Vector{VSCConverter} = VSCConverter[]
    dcdc_converters::Vector{DCDCConverter} = DCDCConverter[]
    energy_routers::Vector{EnergyRouter} = EnergyRouter[]
    # Switches and transformers
    switches::Vector{Switch}            = Switch[]
    transformers_2w::Vector{Transformer2W} = Transformer2W[]
    transformers_3w::Vector{Transformer3W} = Transformer3W[]
    external_grids::Vector{ExternalGrid} = ExternalGrid[]
    # Additional DERs
    pv_systems::Vector{PVSystem}        = PVSystem[]
    charging_stations::Vector{ChargingStation} = ChargingStation[]
    vpps::Vector{VirtualPowerPlant}     = VirtualPowerPlant[]
    microgrids::Vector{Microgrid}       = Microgrid[]
    # Metadata
    name::String                        = ""
    base_mva::Float64                   = 100.0
    base_kv::Float64                    = 110.0
    freq_hz::Float64                    = 50.0
    version::String                     = "1.0"
    created::DateTime                   = now()
    metadata::Dict{Symbol, Any}         = Dict{Symbol, Any}()
end

const ACPowerSystem = PowerSystem{AC}
const DCPowerSystem = PowerSystem{DC}


"""
    HybridPowerSystem

Struct-based hybrid AC/DC power system with linking converters.
"""
@kwdef mutable struct HybridPowerSystem
    ac::PowerSystem{AC}                        = PowerSystem{AC}()
    dc::PowerSystem{DC}                        = PowerSystem{DC}()
    vsc_converters::Vector{VSCConverter}       = VSCConverter[]
    energy_routers::Vector{EnergyRouter}       = EnergyRouter[]
    name::String                               = ""
    base_mva::Float64                          = 100.0
    version::String                            = "1.0"
    created::DateTime                          = now()
    metadata::Dict{Symbol, Any}                = Dict{Symbol, Any}()
end


# ── Element Counts ────────────────────────────────────────────────────────────

nbuses(sys::PowerSystem)           = length(sys.buses)
nbranches(sys::PowerSystem)        = length(sys.branches)
ngenerators(sys::PowerSystem)      = length(sys.generators)
nstatic_generators(sys::PowerSystem) = length(sys.static_generators)
nloads(sys::PowerSystem)           = length(sys.loads)
nstorage(sys::PowerSystem)         = length(sys.storage)
nswitches(sys::PowerSystem)        = length(sys.switches)
nexternal_grids(sys::PowerSystem)  = length(sys.external_grids)

"""Count all converters (VSC + DCDC + EnergyRouters)."""
nconverters(sys::PowerSystem) = length(sys.vsc_converters) + length(sys.dcdc_converters) + length(sys.energy_routers)

"""Count VSC converters only (for backward compatibility with `converters` field)."""
nvsc_converters(sys::PowerSystem) = length(sys.vsc_converters)

"""Count DCDC converters."""
ndcdc_converters(sys::PowerSystem) = length(sys.dcdc_converters)

"""Count energy routers."""
nenergy_routers(sys::PowerSystem) = length(sys.energy_routers)

"""Total in-service generation capacity (MW)."""
function total_gen_capacity(sys::PowerSystem)
    sum(g.pmax_mw for g in sys.generators if g.in_service; init=0.0)
end

"""Total in-service load demand (MW)."""
function total_load(sys::PowerSystem)
    sum(l.p_mw * l.scaling for l in sys.loads if l.in_service; init=0.0)
end


# ── Pretty Printing ──────────────────────────────────────────────────────────

function Base.show(io::IO, sys::PowerSystem{K}) where K
    print(io, "PowerSystem{$K}($(nbuses(sys)) buses, $(nbranches(sys)) branches, $(ngenerators(sys)) gens, $(nloads(sys)) loads)")
end

function Base.show(io::IO, ::MIME"text/plain", sys::PowerSystem{K}) where K
    println(io, "PowerSystem{$K}: \"$(sys.name)\"")
    println(io, "  Base MVA: $(sys.base_mva)")
    println(io, "  Frequency: $(sys.freq_hz) Hz")
    println(io, "  ──────────────────")
    println(io, "  Buses:         $(nbuses(sys))")
    println(io, "  Branches:      $(nbranches(sys))")
    println(io, "  Transformers:  $(length(sys.transformers_2w) + length(sys.transformers_3w))")
    println(io, "  Generators:    $(ngenerators(sys))")
    println(io, "  Loads:         $(nloads(sys))")
    println(io, "  Storage:       $(nstorage(sys))")
    println(io, "  Converters:    $(nconverters(sys))")
    if total_gen_capacity(sys) > 0
        println(io, "  ──────────────────")
        println(io, "  Gen Capacity:  $(round(total_gen_capacity(sys), digits=1)) MW")
        println(io, "  Total Load:    $(round(total_load(sys), digits=1)) MW")
    end
end


# ── Equality Comparison ──────────────────────────────────────────────────────

"""
    Base.==(a::PowerSystem{K}, b::PowerSystem{K}) -> Bool

Compare two PowerSystem instances for structural equality.
Compares all component vectors element-wise and metadata fields.
"""
function Base.:(==)(a::PowerSystem{K}, b::PowerSystem{K}) where K
    a.name == b.name &&
    a.base_mva == b.base_mva &&
    a.base_kv == b.base_kv &&
    a.freq_hz == b.freq_hz &&
    a.version == b.version &&
    a.buses == b.buses &&
    a.branches == b.branches &&
    a.generators == b.generators &&
    a.static_generators == b.static_generators &&
    a.loads == b.loads &&
    a.storage == b.storage &&
    a.vsc_converters == b.vsc_converters &&
    a.dcdc_converters == b.dcdc_converters &&
    a.energy_routers == b.energy_routers &&
    a.switches == b.switches &&
    a.external_grids == b.external_grids
end

"""
    Base.==(a::HybridPowerSystem, b::HybridPowerSystem) -> Bool

Compare two HybridPowerSystem instances for structural equality.
"""
function Base.:(==)(a::HybridPowerSystem, b::HybridPowerSystem)
    a.name == b.name &&
    a.base_mva == b.base_mva &&
    a.version == b.version &&
    a.ac == b.ac &&
    a.dc == b.dc &&
    a.vsc_converters == b.vsc_converters &&
    a.energy_routers == b.energy_routers
end


# ── Copy Operations ──────────────────────────────────────────────────────────

"""
    Base.copy(sys::PowerSystem{K}) -> PowerSystem{K}

Create a shallow copy of a PowerSystem. Component vectors are copied but
individual components are shared references.
"""
function Base.copy(sys::PowerSystem{K}) where K
    PowerSystem{K}(
        buses = copy(sys.buses),
        branches = copy(sys.branches),
        generators = copy(sys.generators),
        static_generators = copy(sys.static_generators),
        loads = copy(sys.loads),
        storage = copy(sys.storage),
        converters = copy(sys.converters),
        vsc_converters = copy(sys.vsc_converters),
        dcdc_converters = copy(sys.dcdc_converters),
        energy_routers = copy(sys.energy_routers),
        switches = copy(sys.switches),
        transformers_2w = copy(sys.transformers_2w),
        transformers_3w = copy(sys.transformers_3w),
        external_grids = copy(sys.external_grids),
        pv_systems = copy(sys.pv_systems),
        charging_stations = copy(sys.charging_stations),
        vpps = copy(sys.vpps),
        microgrids = copy(sys.microgrids),
        name = sys.name,
        base_mva = sys.base_mva,
        base_kv = sys.base_kv,
        freq_hz = sys.freq_hz,
        version = sys.version,
        created = sys.created,
        metadata = copy(sys.metadata),
    )
end

"""
    Base.deepcopy(sys::PowerSystem{K}) -> PowerSystem{K}

Create a deep copy of a PowerSystem. All components are recursively copied.
"""
function Base.deepcopy(sys::PowerSystem{K}) where K
    PowerSystem{K}(
        buses = deepcopy(sys.buses),
        branches = deepcopy(sys.branches),
        generators = deepcopy(sys.generators),
        static_generators = deepcopy(sys.static_generators),
        loads = deepcopy(sys.loads),
        storage = deepcopy(sys.storage),
        converters = deepcopy(sys.converters),
        vsc_converters = deepcopy(sys.vsc_converters),
        dcdc_converters = deepcopy(sys.dcdc_converters),
        energy_routers = deepcopy(sys.energy_routers),
        switches = deepcopy(sys.switches),
        transformers_2w = deepcopy(sys.transformers_2w),
        transformers_3w = deepcopy(sys.transformers_3w),
        external_grids = deepcopy(sys.external_grids),
        pv_systems = deepcopy(sys.pv_systems),
        charging_stations = deepcopy(sys.charging_stations),
        vpps = deepcopy(sys.vpps),
        microgrids = deepcopy(sys.microgrids),
        name = sys.name,
        base_mva = sys.base_mva,
        base_kv = sys.base_kv,
        freq_hz = sys.freq_hz,
        version = sys.version,
        created = sys.created,
        metadata = deepcopy(sys.metadata),
    )
end

"""
    Base.copy(h::HybridPowerSystem) -> HybridPowerSystem

Create a shallow copy of a HybridPowerSystem.
"""
function Base.copy(h::HybridPowerSystem)
    HybridPowerSystem(
        ac = copy(h.ac),
        dc = copy(h.dc),
        vsc_converters = copy(h.vsc_converters),
        energy_routers = copy(h.energy_routers),
        name = h.name,
        base_mva = h.base_mva,
        version = h.version,
    )
end

"""
    Base.deepcopy(h::HybridPowerSystem) -> HybridPowerSystem

Create a deep copy of a HybridPowerSystem.
"""
function Base.deepcopy(h::HybridPowerSystem)
    HybridPowerSystem(
        ac = deepcopy(h.ac),
        dc = deepcopy(h.dc),
        vsc_converters = deepcopy(h.vsc_converters),
        energy_routers = deepcopy(h.energy_routers),
        name = h.name,
        base_mva = h.base_mva,
        version = h.version,
    )
end
