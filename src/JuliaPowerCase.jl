"""
    JuliaPowerCase

A high-performance, type-safe power system **data model** library for Julia.
Provides canonical data structures for representing power system components
without implementing analysis algorithms — an ideal foundation layer for
power flow, OPF, reliability, short-circuit, and stability analysis packages.

# Design Principles
- **No Dictionary** — all containers are strongly-typed structs with concrete fields
- **Symbol Indexing** — compile-time column dispatch via `@define_schema` + `Val{:col}`
- **Parametric Types** — `Bus{AC}` / `Bus{DC}` zero-cost phantom types
- **Multiple Dispatch** — generic algorithms dispatch on component/schema types
- **Lossless Round-Trip** — struct ↔ matrix conversion preserves all fields
"""
module JuliaPowerCase

using LinearAlgebra
using SparseArrays
using Dates

# ═══════════════════════════════════════════════════════════════════════════
# Layer 0 — Types  (phantom types, abstract hierarchy, enums, structs)
# ═══════════════════════════════════════════════════════════════════════════
include("types/abstract.jl")
include("types/bus.jl")
include("types/branch.jl")
include("types/transformer.jl")
include("types/generator.jl")
include("types/load.jl")
include("types/storage.jl")
include("types/converter.jl")
include("types/switch.jl")
include("types/renewable.jl")
include("types/ancillary.jl")
include("types/utils_compat.jl")  # Utils module compatible types

# ═══════════════════════════════════════════════════════════════════════════
# Layer 1 — Indices  (schema macro, per-component schemas, ComponentMatrix)
# ═══════════════════════════════════════════════════════════════════════════
include("indices/schema.jl")
include("indices/bus.jl")
include("indices/branch.jl")
include("indices/generator.jl")
include("indices/load.jl")
include("indices/converter.jl")
include("indices/misc.jl")
include("indices/component_matrix.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Layer 2 — Containers  (PowerSystem, PowerCaseData, Hybrid variants)
# ═══════════════════════════════════════════════════════════════════════════
include("containers/power_system.jl")
include("containers/power_case_data.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Layer 3 — Conversion  (struct ↔ matrix, per-component utilities)
# ═══════════════════════════════════════════════════════════════════════════
include("conversion/to_matrix.jl")
include("conversion/from_matrix.jl")
include("conversion/per_component.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Layer 4 — Topology  (island detection, extraction, graph analysis)
# ═══════════════════════════════════════════════════════════════════════════
include("topology/islands.jl")
include("topology/extract.jl")
include("topology/analysis.jl")
include("topology/hybrid.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Layer 5 — Numbering  (ext2int / int2ext bus renumbering)
# ═══════════════════════════════════════════════════════════════════════════
include("numbering/ext2int.jl")
include("numbering/int2ext.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Layer 6 — I/O  (MATPOWER, Julia case, JSON, ETAP, CSV export)
# ═══════════════════════════════════════════════════════════════════════════
include("io/matpower.jl")
include("io/julia_case.jl")
include("io/json.jl")
include("io/etap.jl")
include("io/export_function.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Layer 7 — Built-in Test Cases
# ═══════════════════════════════════════════════════════════════════════════
include("cases/ieee_transmission.jl")
include("cases/ieee_distribution.jl")
include("cases/hybrid_acdc.jl")

# ═══════════════════════════════════════════════════════════════════════════
# Exports
# ═══════════════════════════════════════════════════════════════════════════

# System tags & abstract types
export AC, DC, SystemKind
export AbstractComponent, AbstractBus, AbstractBranch, AbstractGenerator
export AbstractLoad, AbstractStorage, AbstractConverter, AbstractSwitch

# Enums
export BusType, PQ_BUS, PV_BUS, REF_BUS, ISOLATED_BUS
export GenModel, NONE_MODEL, PIECEWISE_LINEAR, POLYNOMIAL_MODEL

# Exception types
export PowerCaseError, PowerCaseValidationError, ForeignKeyError, SchemaError

# Schema system
export AbstractSchema, @define_schema, colidx, ncols, colnames
export BusSchema, DCBusSchema, BranchSchema, DCBranchSchema, TransformerSchema
export GenSchema, GenCostSchema, SgenSchema, ExtGridSchema
export LoadSchema, FlexLoadSchema, AsymLoadSchema, IndMotorSchema, MotorSchema
export ConverterSchema, VSCSchema, DCDCSchema, ERSchema, StorageSchema, BattACSchema, BattDCSchema
export StorageETAPSchema, SwitchSchema, HVCBSchema, ShuntSchema
export MicrogridSchema, EVSchema, PVArraySchema, PVACSystemSchema
export EnergyRouterCoreSchema, EnergyRouterConvSchema, EnergyRouterSchema, ERPortSchema
export Trafo2WSchema, Trafo3WSchema
export SCResultSchema, FaultSchema, ThreePhaseResultSchema

# ComponentMatrix
export ComponentMatrix, nrows, rawdata, schema_type

# Component structs
export Bus, ACBus, DCBus
export Branch, ACBranch, DCBranch
export Transformer2W, Transformer3W
export Generator, StaticGenerator, ExternalGrid
export Load, AsymmetricLoad, FlexibleLoad, InductionMotor
export Storage, MobileStorage
export VSCConverter, DCDCConverter, EnergyRouterPort, EnergyRouter
export Switch
export PVArray, PVSystem
export ChargingStation, Charger, EVAggregator, V2GService
export VirtualPowerPlant, Microgrid
export CarbonTimeSeries, CarbonScenario, EquipmentCarbon

# Containers
export PowerSystem, ACPowerSystem, DCPowerSystem
export PowerCaseData, ACPowerCaseData, DCPowerCaseData
export HybridPowerSystem, HybridPowerCaseData
export nbuses, nbranches, ngenerators, nloads, nstorage, nconverters
export nstatic_generators, nswitches, nexternal_grids
export nvsc_converters, ndcdc_converters, nenergy_routers
export total_gen_capacity, total_load
export valid_buses, active_buses, active_branches

# Utils compatible types (for validation with Utils/HybridACDCPowerFlow/...)
export JPC, JPC_3ph, JPC_sc, JPC_tp, Fault_sc
export JPC_KEYS, JPC_3PH_KEYS, JPC_SC_KEYS, JPC_TP_KEYS

# Conversion
export to_matrix, from_matrix
export component_table, component_names, summary_table
export merge_systems, deepcopy_case, slice_buses
export validate_case, is_valid, has_warnings, ValidationError
export VM_MIN_REALISTIC, VM_MAX_REALISTIC, VBOUND_MAX_REALISTIC, POWER_LIMIT_LARGE

# Topology
export find_islands, find_islands_dc, find_islands_acdc
export extract_islands, extract_island_subsystem
export detect_islands, IslandInfo
export adjacency_list, degree_vector, n_connected_components
export is_connected, leaf_buses, is_radial, topology_summary

# Numbering
export ext2int, int2ext, renumber!

# I/O
export load_matpower, save_julia_case, load_julia_case
export save_json, export_csv, print_summary
export load_etap_csv

# Built-in cases
export case5, case9, case14
export case_ieee13, case_ieee33
export case_hybrid_5ac3dc

end # module JuliaPowerCase
