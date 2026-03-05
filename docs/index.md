# JuliaPowerCase.jl Documentation

## Overview

**JuliaPowerCase** is a high-performance, type-safe power system **data model** library for Julia. It provides canonical data structures for representing power system components without implementing analysis algorithms — making it an ideal foundation layer for power flow, OPF, reliability, short-circuit, and stability analysis packages.

## Design Principles

| Principle | Description |
|-----------|-------------|
| **No Dictionary** | All containers are strongly-typed structs with concrete fields |
| **Symbol Indexing** | Compile-time column dispatch via `@define_schema` + `Val{:col}` |
| **Parametric Types** | `Bus{AC}` / `Bus{DC}` zero-cost phantom types |
| **Multiple Dispatch** | Generic algorithms dispatch on component/schema types |
| **Lossless Round-Trip** | Struct ↔ matrix conversion preserves all fields |

## Architecture

JuliaPowerCase uses an 8-layer architecture:

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 7: Built-in Test Cases                               │
│          case5(), case14(), case_ieee33(), ...             │
├─────────────────────────────────────────────────────────────┤
│ Layer 6: I/O                                               │
│          MATPOWER, Julia case, JSON, ETAP, CSV             │
├─────────────────────────────────────────────────────────────┤
│ Layer 5: Numbering                                         │
│          ext2int / int2ext bus renumbering                 │
├─────────────────────────────────────────────────────────────┤
│ Layer 4: Topology                                          │
│          Island detection, extraction, graph analysis      │
├─────────────────────────────────────────────────────────────┤
│ Layer 3: Conversion                                        │
│          Struct ↔ Matrix, per-component utilities          │
├─────────────────────────────────────────────────────────────┤
│ Layer 2: Containers                                        │
│          PowerSystem, PowerCaseData, Hybrid variants       │
├─────────────────────────────────────────────────────────────┤
│ Layer 1: Indices                                           │
│          Schema macro, per-component schemas, ComponentMatrix│
├─────────────────────────────────────────────────────────────┤
│ Layer 0: Types                                             │
│          Phantom types, abstract hierarchy, enums, structs │
└─────────────────────────────────────────────────────────────┘
```

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

# Symbol-based column access (zero overhead due to compile-time dispatch)
voltage = jpc.bus[:, :VM]
```

### Hybrid AC/DC Systems

```julia
using JuliaPowerCase

# Create hybrid system with AC and DC subsystems
hybrid = HybridPowerSystem()

# Build AC side
push!(hybrid.ac.buses, Bus{AC}(index=1, name="AC-1", bus_type=REF_BUS))
push!(hybrid.ac.buses, Bus{AC}(index=2, name="AC-2", bus_type=PQ_BUS))

# Build DC side
push!(hybrid.dc.buses, Bus{DC}(index=1, name="DC-1"))
push!(hybrid.dc.buses, Bus{DC}(index=2, name="DC-2"))

# Add VSC converter linking AC bus 2 to DC bus 1
push!(hybrid.vsc_converters, VSCConverter(
    index=1, bus_ac=2, bus_dc=1,
    p_set_mw=50.0, control_mode=:pq
))
```

### Built-in Test Cases

```julia
using JuliaPowerCase

# IEEE transmission test cases
sys5 = case5()           # 5-bus system
sys9 = case9()           # IEEE 9-bus
sys14 = case14()         # IEEE 14-bus

# IEEE distribution test cases
sys13 = case_ieee13()    # IEEE 13-bus radial
sys33 = case_ieee33()    # IEEE 33-bus radial

# Hybrid AC/DC test case
hybrid = case_hybrid_5ac3dc()  # 5 AC buses + 3 DC buses
```

## Documentation Structure

| Document | Description |
|----------|-------------|
| [Types Reference](types.md) | Component type definitions (Bus, Branch, Generator, etc.) |
| [Containers](containers.md) | PowerSystem and PowerCaseData documentation |
| [Topology](topology.md) | Island detection and graph analysis |
| [I/O Formats](io.md) | MATPOWER, JSON, CSV import/export |
| [API Reference](api_reference.md) | Complete API listing |

## Comparison with Other Libraries

| Feature | JuliaPowerCase | PowerSystems.jl | pandapower |
|---------|---------------|-----------------|------------|
| Language | Julia | Julia | Python |
| Type Safety | ✅ Parametric | ✅ Abstract | ❌ Dict |
| AC/DC | ✅ Unified | ⚠️ Separate | ✅ Unified |
| Schema System | ✅ Compile-time | ❌ Runtime | ❌ Runtime |
| MATPOWER I/O | ✅ Native | ⚠️ Via packages | ✅ Native |

## License

MIT License - see LICENSE file for details.
