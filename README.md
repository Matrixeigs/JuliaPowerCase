# JuliaPowerCase.jl

[![Julia](https://img.shields.io/badge/Julia-1.9+-blue.svg)](https://julialang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**JuliaPowerCase** is a high-performance, type-safe power system **data model** library for Julia. It provides canonical data structures for representing power system components without implementing any analysis algorithms — making it an ideal foundation layer for power flow, OPF, reliability, short-circuit, and stability analysis packages.

## Features

- 🔒 **Type-Safe**: Parametric types (`Bus{AC}`, `Bus{DC}`) with zero-cost phantom type tags
- ⚡ **High Performance**: Compile-time column dispatch via `@define_schema` + `Val{:col}`
- 🔄 **Dual Containers**: Struct-based (`PowerSystem`) and matrix-based (`PowerCaseData`)
- 🌐 **Hybrid AC/DC**: Native support for hybrid AC/DC systems and converters
- 📊 **MATPOWER Compatible**: Seamless I/O with MATPOWER case files
- 🧩 **Modular Architecture**: 8-layer design for extensibility

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/Matrixeigs/JuliaPowerCase.jl")
```

Or for local development:

```julia
] dev /path/to/JuliaPowerCase
```

## Quick Start

### Struct-based API (PowerSystem)

```julia
using JuliaPowerCase

# Create an AC power system
sys = PowerSystem{AC}()

# Add buses
push!(sys.buses, Bus{AC}(index=1, name="Slack", bus_type=REF_BUS, vm_pu=1.0))
push!(sys.buses, Bus{AC}(index=2, name="Load", bus_type=PQ_BUS, pd_mw=100.0))

# Add a generator
push!(sys.generators, Generator(index=1, bus=1, pg_mw=150.0, pmax_mw=200.0))

# Add a branch
push!(sys.branches, Branch{AC}(index=1, from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1))

# Query system
println("Buses: ", nbuses(sys))
println("Total capacity: ", total_gen_capacity(sys), " MW")
```

### Matrix-based API (PowerCaseData)

```julia
using JuliaPowerCase

# Create MATPOWER-style case
jpc = PowerCaseData{AC, Float64}()

# Resize and populate bus matrix
jpc.bus = ComponentMatrix{BusSchema}(3)
jpc.bus[1, :I] = 1;  jpc.bus[1, :TYPE] = 3;  jpc.bus[1, :VM] = 1.0
jpc.bus[2, :I] = 2;  jpc.bus[2, :TYPE] = 1;  jpc.bus[2, :PD] = 100.0
jpc.bus[3, :I] = 3;  jpc.bus[3, :TYPE] = 1;  jpc.bus[3, :PD] = 80.0

# Symbol-based column access (zero overhead)
voltage = jpc.bus[:, :VM]
```

### Utils-Compatible Types (JPC)

For interoperability with `Utils` module and power flow solvers:

```julia
using JuliaPowerCase

# Create JPC structure (MATPOWER matrix format)
jpc = JPC()
jpc["baseMVA"] = 100.0
jpc["busAC"] = zeros(10, 22)  # 10 buses

# Dictionary-style access
jpc["busAC"][1, :] = [1, 3, 0, 0, 0, 0, 1, 1.0, 0, 110, 1, 1.05, 0.95, 1, 1, 0, 0, 0, 0, 100]
```

### Built-in Test Cases

```julia
using JuliaPowerCase

# IEEE test cases (struct-based)
sys5 = case5()           # 5-bus system
sys14 = case14()         # IEEE 14-bus

# Distribution test cases
sys33 = case_ieee33()    # IEEE 33-bus radial distribution

# Hybrid AC/DC
hybrid = case_hybrid_5ac3dc()
```

## Architecture

JuliaPowerCase is organized in 8 layers:

```
Layer 0: Types         - Phantom types, abstract hierarchy, enums, component structs
Layer 1: Indices       - Schema macro, column definitions, ComponentMatrix
Layer 2: Containers    - PowerSystem, PowerCaseData, Hybrid variants
Layer 3: Conversion    - Struct ↔ matrix bidirectional conversion
Layer 4: Topology      - Island detection, graph analysis
Layer 5: Numbering     - External ↔ internal bus renumbering
Layer 6: I/O           - MATPOWER, JSON, ETAP, CSV import/export
Layer 7: Test Cases    - Built-in IEEE and custom test systems
```

## Design Principles

### 1. No Dictionary Overhead

All containers use strongly-typed structs with concrete fields:

```julia
# ✗ Slow: Dictionary access
mpc["bus"][1, 8]  # What is column 8?

# ✓ Fast: Schema-based access
jpc.bus[1, :VM]   # Compile-time resolved, self-documenting
```

### 2. Phantom Types for AC/DC

Zero-cost type tags differentiate AC and DC components:

```julia
struct Bus{K<:SystemKind} <: AbstractBus
    # K is either AC or DC - no runtime cost
end

const ACBus = Bus{AC}
const DCBus = Bus{DC}
```

### 3. Schema-Driven Column Access

The `@define_schema` macro generates compile-time column indices:

```julia
@define_schema BusSchema  I TYPE PD QD GS BS AREA VM VA BASE_KV ZONE VMAX VMIN

colidx(BusSchema, Val(:VM))  # → 8 (constant at compile-time)
```

## Component Types

### Network Components

| Component | AC | DC | Description |
|-----------|----|----|-------------|
| `Bus{K}` | ✓ | ✓ | Network node |
| `Branch{K}` | ✓ | ✓ | Line/cable |
| `Transformer2W` | ✓ | - | Two-winding transformer |
| `Transformer3W` | ✓ | - | Three-winding transformer |
| `Generator` | ✓ | - | Synchronous generator |
| `StaticGenerator{K}` | ✓ | ✓ | Static (inverter-based) generator |
| `ExternalGrid` | ✓ | - | Infinite bus / grid connection |
| `Load{K}` | ✓ | ✓ | Constant/flexible load |
| `Storage{K}` | ✓ | ✓ | Battery/storage device |

### Converters & DERs

| Component | Description |
|-----------|-------------|
| `VSCConverter` | Voltage source converter (AC/DC) |
| `DCDCConverter` | DC-DC converter |
| `EnergyRouter` | Multi-port energy router |
| `PVSystem` | Photovoltaic system |
| `ChargingStation` | EV charging station |
| `VirtualPowerPlant` | VPP aggregator |
| `Microgrid` | Islanded microgrid |

## I/O Functions

```julia
# MATPOWER format
sys = load_matpower("case14.m")
save_julia_case(sys, "case14.jl")

# JSON format
save_json(sys, "case14.json")

# CSV export
export_csv(sys, "output_dir/")

# ETAP import
sys = load_etap_csv("etap_export/")
```

## Topology Analysis

```julia
using JuliaPowerCase

sys = case_ieee33()

# Island detection
islands = find_islands(sys)

# Graph metrics
adj = adjacency_list(sys)
deg = degree_vector(sys)

# Radial network check
is_radial(sys)  # → true for distribution networks

# Summary
topology_summary(sys)
```

## Utils Compatibility

JuliaPowerCase provides types compatible with the `Utils` module for power flow validation:

| Type | Purpose |
|------|---------|
| `JPC` | Matrix-based power flow (MATPOWER-style) |
| `JPC_3ph` | Three-phase unbalanced power flow |
| `JPC_sc` | Short-circuit calculation |
| `JPC_tp` | Topology analysis |
| `Fault_sc` | Fault definition |

```julia
# Convert between formats
jpc = JPC()
jpc["busAC"] = to_matrix(sys.buses)  # PowerSystem → JPC matrix

# Short-circuit fault definition
fault = Fault_sc()
fault.fault_type = :single_line_ground
fault.fault_bus = 5
fault.fault_impedance = 0.0 + 0.1im
```

## API Reference

See the [API Documentation](docs/api.md) for complete function and type reference.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Citation

If you use JuliaPowerCase in your research, please cite:

```bibtex
@software{JuliaPowerCase,
  author = {Tianyang Zhao},
  title = {JuliaPowerCase.jl: Type-Safe Power System Data Modeling},
  year = {2026},
  url = {https://github.com/Matrixeigs/JuliaPowerCase.jl}
}
```
