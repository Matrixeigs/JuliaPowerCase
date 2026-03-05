# Containers Reference

JuliaPowerCase provides two parallel container systems for power system data:

| Container | Style | Use Case |
|-----------|-------|----------|
| `PowerSystem{K}` | Struct-based | Object-oriented workflows, type safety |
| `PowerCaseData{K}` | Matrix-based | MATPOWER compatibility, numerical algorithms |

Both can represent identical systems and convert between each other.

---

## Struct-Based Containers

### `PowerSystem{K<:SystemKind}`

Type-safe container holding vectors of component structs.

```julia
@kwdef mutable struct PowerSystem{K<:SystemKind}
    # Core components
    buses::Vector{Bus{K}}                 = Bus{K}[]
    branches::Vector{Branch{K}}           = Branch{K}[]
    generators::Vector{Generator}         = Generator[]
    loads::Vector{Load{K}}                = Load{K}[]
    storage::Vector{Storage{K}}           = Storage{K}[]
    
    # Converters
    vsc_converters::Vector{VSCConverter}  = VSCConverter[]
    dcdc_converters::Vector{DCDCConverter}= DCDCConverter[]
    energy_routers::Vector{EnergyRouter}  = EnergyRouter[]
    
    # Other equipment
    switches::Vector{Switch}              = Switch[]
    transformers_2w::Vector{Transformer2W}= Transformer2W[]
    external_grids::Vector{ExternalGrid}  = ExternalGrid[]
    static_generators::Vector{StaticGenerator{K}} = StaticGenerator{K}[]
    
    # Distributed energy resources
    pv_systems::Vector{PVSystem}          = PVSystem[]
    charging_stations::Vector{ChargingStation} = ChargingStation[]
    
    # Metadata
    name::String                          = ""
    base_mva::Float64                     = 100.0
    base_kv::Float64                      = 110.0
    freq_hz::Float64                      = 50.0
    version::String                       = "1.0"
    created::DateTime                     = now()
    metadata::Dict{Symbol, Any}           = Dict{Symbol, Any}()
end
```

#### Type Aliases

```julia
const ACPowerSystem = PowerSystem{AC}
const DCPowerSystem = PowerSystem{DC}
```

#### Query Functions

```julia
nbuses(sys::PowerSystem)           # Number of buses
nbranches(sys::PowerSystem)        # Number of branches
ngenerators(sys::PowerSystem)      # Number of generators
nloads(sys::PowerSystem)           # Number of loads
nstorage(sys::PowerSystem)         # Number of storage units
nconverters(sys::PowerSystem)      # Total converters (VSC + DCDC + ER)
nvsc_converters(sys::PowerSystem)  # VSC converters only
ndcdc_converters(sys::PowerSystem) # DC-DC converters only
nenergy_routers(sys::PowerSystem)  # Energy routers only
nswitches(sys::PowerSystem)        # Number of switches
nexternal_grids(sys::PowerSystem)  # External grid connections

total_gen_capacity(sys::PowerSystem)  # Total in-service gen capacity (MW)
total_load(sys::PowerSystem)          # Total in-service load (MW)
```

#### Example Usage

```julia
using JuliaPowerCase

# Create empty AC system
sys = PowerSystem{AC}(name="IEEE 5-Bus", base_mva=100.0)

# Add buses
push!(sys.buses, Bus{AC}(index=1, name="Slack", bus_type=REF_BUS, vm_pu=1.05))
push!(sys.buses, Bus{AC}(index=2, name="Gen", bus_type=PV_BUS, vm_pu=1.02))
push!(sys.buses, Bus{AC}(index=3, name="Load1", bus_type=PQ_BUS, pd_mw=100.0))

# Add generators
push!(sys.generators, Generator(index=1, bus=1, pg_mw=150.0, pmax_mw=300.0))
push!(sys.generators, Generator(index=2, bus=2, pg_mw=80.0, pmax_mw=150.0))

# Add branches
push!(sys.branches, Branch{AC}(index=1, from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1))
push!(sys.branches, Branch{AC}(index=2, from_bus=2, to_bus=3, r_pu=0.02, x_pu=0.2))

# Query
println("Buses: ", nbuses(sys))
println("Capacity: ", total_gen_capacity(sys), " MW")
println("Load: ", total_load(sys), " MW")
```

---

### `HybridPowerSystem`

Container for coupled AC/DC systems with linking converters.

```julia
@kwdef mutable struct HybridPowerSystem
    ac::PowerSystem{AC}                   = PowerSystem{AC}()
    dc::PowerSystem{DC}                   = PowerSystem{DC}()
    vsc_converters::Vector{VSCConverter}  = VSCConverter[]
    energy_routers::Vector{EnergyRouter}  = EnergyRouter[]
    
    name::String                          = ""
    base_mva::Float64                     = 100.0
    version::String                       = "1.0"
    created::DateTime                     = now()
    metadata::Dict{Symbol, Any}           = Dict{Symbol, Any}()
end
```

#### Example Usage

```julia
# Create hybrid system
hybrid = HybridPowerSystem(name="Hybrid Test", base_mva=100.0)

# Build AC side
push!(hybrid.ac.buses, Bus{AC}(index=1, bus_type=REF_BUS, vm_pu=1.05))
push!(hybrid.ac.buses, Bus{AC}(index=2, bus_type=PQ_BUS, pd_mw=50.0))
push!(hybrid.ac.branches, Branch{AC}(index=1, from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1))
push!(hybrid.ac.generators, Generator(index=1, bus=1, pg_mw=100.0))

# Build DC side
push!(hybrid.dc.buses, Bus{DC}(index=1, vm_pu=1.0))
push!(hybrid.dc.buses, Bus{DC}(index=2, vm_pu=1.0, pd_mw=30.0))
push!(hybrid.dc.branches, Branch{DC}(index=1, from_bus=1, to_bus=2, r_pu=0.005))

# Add VSC converter linking AC bus 2 to DC bus 1
push!(hybrid.vsc_converters, VSCConverter(
    index=1, bus_ac=2, bus_dc=1,
    p_set_mw=40.0, control_mode=:pq, eta=0.98
))
```

---

## Matrix-Based Containers

### `PowerCaseData{K, T}`

MATPOWER-compatible container using `ComponentMatrix` for each component type.

```julia
@kwdef mutable struct PowerCaseData{K<:SystemKind, T<:Real}
    # System metadata
    base_mva::T                           = T(100.0)
    version::String                       = "1.0"
    
    # Core matrices
    bus::ComponentMatrix{BusSchema, T}    = ComponentMatrix{BusSchema, T}()
    branch::ComponentMatrix{BranchSchema, T} = ComponentMatrix{BranchSchema, T}()
    gen::ComponentMatrix{GenSchema, T}    = ComponentMatrix{GenSchema, T}()
    gencost::ComponentMatrix{GenCostSchema, T} = ComponentMatrix{GenCostSchema, T}()
    
    # Extension matrices (DC networks)
    dc_bus::ComponentMatrix{DCBusSchema, T} = ComponentMatrix{DCBusSchema, T}()
    dc_branch::ComponentMatrix{DCBranchSchema, T} = ComponentMatrix{DCBranchSchema, T}()
    vsc::ComponentMatrix{VSCSchema, T}    = ComponentMatrix{VSCSchema, T}()
    
    # Other components
    load::ComponentMatrix{LoadSchema, T}  = ComponentMatrix{LoadSchema, T}()
    storage::ComponentMatrix{StorageSchema, T} = ComponentMatrix{StorageSchema, T}()
end
```

#### Type Aliases

```julia
const ACPowerCaseData = PowerCaseData{AC}
const DCPowerCaseData = PowerCaseData{DC}
```

### `ComponentMatrix{S, T}`

Schema-indexed matrix wrapper providing symbol-based column access.

```julia
struct ComponentMatrix{S<:AbstractSchema, T<:Real}
    data::Matrix{T}
end
```

#### Symbol-Based Indexing

```julia
# Column access by symbol (compile-time dispatch)
jpc.bus[1, :I]         # Bus number (column 1)
jpc.bus[1, :TYPE]      # Bus type (column 2)
jpc.bus[1, :VM]        # Voltage magnitude
jpc.bus[1, :PD]        # Active load

# Row/column slicing
jpc.bus[:, :VM]        # All voltage magnitudes
jpc.bus[1:5, :PD]      # First 5 bus loads
```

#### Example Usage

```julia
using JuliaPowerCase

# Create MATPOWER-style case
jpc = PowerCaseData{AC, Float64}()
jpc.base_mva = 100.0

# Initialize bus matrix (3 buses)
jpc.bus = ComponentMatrix{BusSchema}(3)

# Populate using symbol indexing
jpc.bus[1, :I] = 1;  jpc.bus[1, :TYPE] = 3;  jpc.bus[1, :VM] = 1.05
jpc.bus[2, :I] = 2;  jpc.bus[2, :TYPE] = 2;  jpc.bus[2, :VM] = 1.02
jpc.bus[3, :I] = 3;  jpc.bus[3, :TYPE] = 1;  jpc.bus[3, :PD] = 100.0

# Initialize generator matrix
jpc.gen = ComponentMatrix{GenSchema}(2)
jpc.gen[1, :BUS] = 1;  jpc.gen[1, :PG] = 150.0;  jpc.gen[1, :PMAX] = 300.0
jpc.gen[2, :BUS] = 2;  jpc.gen[2, :PG] = 80.0;   jpc.gen[2, :PMAX] = 150.0

# Query
nrows(jpc.bus)    # 3
ncols(jpc.bus)    # depends on BusSchema
```

---

### `HybridPowerCaseData`

Matrix-based hybrid AC/DC container.

```julia
@kwdef mutable struct HybridPowerCaseData{T<:Real}
    ac::PowerCaseData{AC, T}              = PowerCaseData{AC, T}()
    dc::PowerCaseData{DC, T}              = PowerCaseData{DC, T}()
    vsc::ComponentMatrix{VSCSchema, T}    = ComponentMatrix{VSCSchema, T}()
    base_mva::T                           = T(100.0)
end
```

---

## Schema System

Schemas define column mappings for `ComponentMatrix`. Each schema type provides:
- `colidx(::Type{S}, ::Val{:col})` — column index for symbol
- `ncols(::Type{S})` — total column count
- `colnames(::Type{S})` — vector of column symbols

### BusSchema

Standard MATPOWER bus matrix columns:

| Column | Symbol | Description |
|--------|--------|-------------|
| 1 | `:I` | Bus number |
| 2 | `:TYPE` | Bus type (1=PQ, 2=PV, 3=REF, 4=ISO) |
| 3 | `:PD` | Active load demand (MW) |
| 4 | `:QD` | Reactive load demand (MVAr) |
| 5 | `:GS` | Shunt conductance (MW at V=1) |
| 6 | `:BS` | Shunt susceptance (MVAr at V=1) |
| 7 | `:AREA` | Area number |
| 8 | `:VM` | Voltage magnitude (p.u.) |
| 9 | `:VA` | Voltage angle (degrees) |
| 10 | `:BASE_KV` | Base voltage (kV) |
| 11 | `:ZONE` | Zone number |
| 12 | `:VMAX` | Maximum voltage (p.u.) |
| 13 | `:VMIN` | Minimum voltage (p.u.) |

### GenSchema

Standard MATPOWER generator columns:

| Column | Symbol | Description |
|--------|--------|-------------|
| 1 | `:BUS` | Bus number |
| 2 | `:PG` | Active power output (MW) |
| 3 | `:QG` | Reactive power output (MVAr) |
| 4 | `:QMAX` | Maximum Q (MVAr) |
| 5 | `:QMIN` | Minimum Q (MVAr) |
| 6 | `:VG` | Voltage setpoint (p.u.) |
| 7 | `:MBASE` | Machine base (MVA) |
| 8 | `:STATUS` | Status (1=on, 0=off) |
| 9 | `:PMAX` | Maximum P (MW) |
| 10 | `:PMIN` | Minimum P (MW) |

### BranchSchema

Standard MATPOWER branch columns:

| Column | Symbol | Description |
|--------|--------|-------------|
| 1 | `:F_BUS` | From bus number |
| 2 | `:T_BUS` | To bus number |
| 3 | `:BR_R` | Resistance (p.u.) |
| 4 | `:BR_X` | Reactance (p.u.) |
| 5 | `:BR_B` | Total charging susceptance (p.u.) |
| 6 | `:RATE_A` | Normal rating (MVA) |
| 7 | `:RATE_B` | Short-term rating (MVA) |
| 8 | `:RATE_C` | Emergency rating (MVA) |
| 9 | `:TAP` | Tap ratio |
| 10 | `:SHIFT` | Phase shift (degrees) |
| 11 | `:STATUS` | Status (1=on, 0=off) |

---

## Container Conversion

### PowerSystem → PowerCaseData

```julia
jpc = to_matrix(sys::PowerSystem{K}) -> PowerCaseData{K}
```

### PowerCaseData → PowerSystem

```julia
sys = from_matrix(jpc::PowerCaseData{K}) -> PowerSystem{K}
```

### Example

```julia
# Create struct-based system
sys = case14()  # IEEE 14-bus

# Convert to matrix form
jpc = to_matrix(sys)
println("Buses: ", nrows(jpc.bus))

# Modify in matrix form
jpc.bus[5, :PD] *= 1.5  # Increase load by 50%

# Convert back to struct form
sys_modified = from_matrix(jpc)
```

---

## Utils-Compatible Types (JPC)

For interoperability with the `Utils` module and external solvers:

```julia
# JPC is a Dict{String, Any} wrapper
jpc = JPC()
jpc["baseMVA"] = 100.0
jpc["busAC"] = zeros(Float64, 10, 22)  # 10 AC buses

# Dictionary-style access
nb = size(jpc["busAC"], 1)

# Predefined keys
JPC_KEYS = ["baseMVA", "version", "busAC", "branchAC", "genAC", ...]
```

### JPC Variants

| Type | Purpose |
|------|---------|
| `JPC` | Standard power flow case |
| `JPC_3ph` | Three-phase unbalanced case |
| `JPC_sc` | Short-circuit analysis case |
| `JPC_tp` | Transient stability case |

---

## Best Practices

### When to Use PowerSystem

- Building systems programmatically
- Type-safe component manipulation
- Object-oriented workflows
- Field-level validation

### When to Use PowerCaseData

- MATPOWER file I/O
- Numerical algorithms requiring matrix operations
- Interoperability with existing MATPOWER tools
- Batch processing of component data

### Hybrid Workflows

```julia
# Load from MATPOWER
jpc = load_matpower("case14.m")

# Convert to structs for manipulation
sys = from_matrix(jpc)

# Modify with type safety
for bus in sys.buses
    if bus.bus_type == PQ_BUS
        bus.pd_mw *= 0.8  # Reduce load by 20%
    end
end

# Convert back for solver
jpc_modified = to_matrix(sys)
```
