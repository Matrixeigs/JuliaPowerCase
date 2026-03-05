# API Reference

Complete listing of all exported types, functions, and constants in JuliaPowerCase.

---

## Phantom Types & Abstract Hierarchy

### System Tags

| Export | Type | Description |
|--------|------|-------------|
| `SystemKind` | abstract type | Supertype for AC/DC tags |
| `AC` | struct | Alternating current tag |
| `DC` | struct | Direct current tag |

### Abstract Types

| Export | Supertype | Description |
|--------|-----------|-------------|
| `AbstractComponent` | — | Base for all components |
| `AbstractBus` | AbstractComponent | Bus types |
| `AbstractBranch` | AbstractComponent | Branch types |
| `AbstractGenerator` | AbstractComponent | Generator types |
| `AbstractLoad` | AbstractComponent | Load types |
| `AbstractStorage` | AbstractComponent | Storage types |
| `AbstractConverter` | AbstractComponent | Converter types |
| `AbstractSwitch` | AbstractComponent | Switch types |

---

## Enums

### BusType

```julia
@enum BusType::Int32 begin
    PQ_BUS       = 1
    PV_BUS       = 2
    REF_BUS      = 3
    ISOLATED_BUS = 4
end
```

### GenModel

```julia
@enum GenModel::Int32 begin
    NONE_MODEL = 0
    PIECEWISE_LINEAR = 1
    POLYNOMIAL_MODEL = 2
end
```

---

## Component Structs

### Buses

| Export | Description |
|--------|-------------|
| `Bus{K}` | Parametric bus (AC/DC) |
| `ACBus` | Alias for `Bus{AC}` |
| `DCBus` | Alias for `Bus{DC}` |

### Branches

| Export | Description |
|--------|-------------|
| `Branch{K}` | Parametric branch (AC/DC) |
| `ACBranch` | Alias for `Branch{AC}` |
| `DCBranch` | Alias for `Branch{DC}` |
| `Transformer2W` | Two-winding transformer |
| `Transformer3W` | Three-winding transformer |

### Generators

| Export | Description |
|--------|-------------|
| `Generator` | Synchronous generator |
| `StaticGenerator{K}` | Static generator (PV, wind) |
| `ExternalGrid` | External grid connection |

### Loads

| Export | Description |
|--------|-------------|
| `Load{K}` | General load |
| `AsymmetricLoad` | Unbalanced three-phase load |
| `FlexibleLoad{K}` | Demand response load |
| `InductionMotor` | Motor load |

### Storage

| Export | Description |
|--------|-------------|
| `Storage{K}` | Energy storage (battery) |
| `MobileStorage` | Mobile/EV storage |

### Converters

| Export | Description |
|--------|-------------|
| `VSCConverter` | Voltage source converter |
| `DCDCConverter` | DC-DC converter |
| `EnergyRouterPort` | Single port of energy router |
| `EnergyRouter` | Multi-port energy router |

### Switches

| Export | Description |
|--------|-------------|
| `Switch` | Circuit breaker/switch |

### DERs

| Export | Description |
|--------|-------------|
| `PVArray` | Photovoltaic array |
| `PVSystem` | Complete PV system |
| `ChargingStation` | EV charging station |
| `Charger` | Individual charger |
| `EVAggregator` | EV fleet aggregator |
| `V2GService` | Vehicle-to-grid service |
| `VirtualPowerPlant` | VPP aggregation |
| `Microgrid` | Microgrid container |

### Carbon Tracking

| Export | Description |
|--------|-------------|
| `CarbonTimeSeries` | Time series carbon data |
| `CarbonScenario` | Carbon scenario |
| `EquipmentCarbon` | Equipment carbon footprint |

---

## Containers

### Struct-Based

| Export | Description |
|--------|-------------|
| `PowerSystem{K}` | Main system container |
| `ACPowerSystem` | Alias for `PowerSystem{AC}` |
| `DCPowerSystem` | Alias for `PowerSystem{DC}` |
| `HybridPowerSystem` | Coupled AC/DC system |

### Matrix-Based

| Export | Description |
|--------|-------------|
| `PowerCaseData{K,T}` | MATPOWER-style container |
| `ACPowerCaseData` | Alias for `PowerCaseData{AC,Float64}` |
| `DCPowerCaseData` | Alias for `PowerCaseData{DC,Float64}` |
| `HybridPowerCaseData` | Matrix-based hybrid system |
| `ComponentMatrix{S,T}` | Schema-indexed matrix |

---

## Container Query Functions

| Function | Returns | Description |
|----------|---------|-------------|
| `nbuses(sys)` | Int | Number of buses |
| `nbranches(sys)` | Int | Number of branches |
| `ngenerators(sys)` | Int | Number of generators |
| `nstatic_generators(sys)` | Int | Number of static generators |
| `nloads(sys)` | Int | Number of loads |
| `nstorage(sys)` | Int | Number of storage units |
| `nconverters(sys)` | Int | Total converters |
| `nvsc_converters(sys)` | Int | VSC converters |
| `ndcdc_converters(sys)` | Int | DC-DC converters |
| `nenergy_routers(sys)` | Int | Energy routers |
| `nswitches(sys)` | Int | Number of switches |
| `nexternal_grids(sys)` | Int | External grid connections |
| `total_gen_capacity(sys)` | Float64 | Total generation (MW) |
| `total_load(sys)` | Float64 | Total load (MW) |

---

## Schema System

### Schema Types

| Export | Description |
|--------|-------------|
| `AbstractSchema` | Base schema type |
| `BusSchema` | AC bus columns |
| `DCBusSchema` | DC bus columns |
| `BranchSchema` | AC branch columns |
| `DCBranchSchema` | DC branch columns |
| `GenSchema` | Generator columns |
| `GenCostSchema` | Generator cost columns |
| `LoadSchema` | Load columns |
| `StorageSchema` | Storage columns |
| `VSCSchema` | VSC converter columns |
| `TransformerSchema` | Transformer columns |
| `SwitchSchema` | Switch columns |

### Schema Functions

| Function | Description |
|----------|-------------|
| `@define_schema` | Macro to define new schemas |
| `colidx(S, Val{:col})` | Get column index for symbol |
| `ncols(S)` | Number of columns in schema |
| `colnames(S)` | Vector of column symbols |

### ComponentMatrix Functions

| Function | Description |
|----------|-------------|
| `nrows(cm)` | Number of rows |
| `rawdata(cm)` | Underlying matrix |
| `schema_type(cm)` | Schema type of matrix |

---

## Conversion Functions

| Function | Description |
|----------|-------------|
| `to_matrix(sys)` | PowerSystem → PowerCaseData |
| `from_matrix(jpc)` | PowerCaseData → PowerSystem |
| `component_table(sys, :buses)` | Get formatted component table |
| `component_names(sys)` | List of component types |
| `summary_table(sys)` | Summary statistics |

### System Operations

| Function | Description |
|----------|-------------|
| `merge_systems(sys1, sys2)` | Merge two systems |
| `deepcopy_case(jpc)` | Deep copy of case data |
| `slice_buses(sys, indices)` | Extract subsystem by buses |

### Validation

| Function | Description |
|----------|-------------|
| `validate_case(sys)` | Full validation |
| `is_valid(sys)` | Quick validity check |
| `has_warnings(sys)` | Check for warnings |

### Constants

| Export | Value | Description |
|--------|-------|-------------|
| `VM_MIN_REALISTIC` | 0.8 | Minimum realistic voltage |
| `VM_MAX_REALISTIC` | 1.2 | Maximum realistic voltage |
| `VBOUND_MAX_REALISTIC` | 1.5 | Maximum voltage bound |
| `POWER_LIMIT_LARGE` | 9999 | Large power limit |

---

## Topology Functions

### Island Detection

| Function | Description |
|----------|-------------|
| `find_islands(jpc)` | Find islands in AC system |
| `find_islands_dc(dc_bus, dc_branch)` | Find islands in DC system |
| `find_islands_acdc(hjpc)` | Find islands in hybrid system |
| `detect_islands(sys)` | High-level island detection |

### Island Extraction

| Function | Description |
|----------|-------------|
| `extract_islands(sys)` | Extract all islands |
| `extract_island_subsystem(sys, island)` | Extract single island |

### Graph Analysis

| Function | Description |
|----------|-------------|
| `adjacency_list(sys)` | Build adjacency list |
| `degree_vector(sys)` | Bus degrees |
| `n_connected_components(sys)` | Count components |
| `is_connected(sys)` | Check connectivity |
| `leaf_buses(sys)` | Find leaf buses |
| `is_radial(sys)` | Check radial topology |
| `topology_summary(sys)` | Topology statistics |

### Types

| Export | Description |
|--------|-------------|
| `IslandInfo` | Island information struct |

---

## Numbering Functions

| Function | Description |
|----------|-------------|
| `ext2int(jpc)` | External → internal bus numbering |
| `int2ext(jpc, i2e)` | Internal → external bus numbering |
| `renumber!(sys)` | Renumber buses in-place |

---

## I/O Functions

### MATPOWER

| Function | Description |
|----------|-------------|
| `load_matpower(filepath)` | Load `.m` file |

### Julia Case

| Function | Description |
|----------|-------------|
| `save_julia_case(filepath, sys)` | Save as Julia source |
| `load_julia_case(filepath)` | Load Julia case file |

### JSON

| Function | Description |
|----------|-------------|
| `save_json(filepath, sys)` | Export to JSON |

### CSV

| Function | Description |
|----------|-------------|
| `export_csv(directory, sys)` | Export to CSV files |

### ETAP

| Function | Description |
|----------|-------------|
| `load_etap_csv(bus_file, branch_file)` | Import ETAP CSV |

### Display

| Function | Description |
|----------|-------------|
| `print_summary(sys)` | Print formatted summary |

---

## Built-in Test Cases

### Transmission Cases

| Function | Description |
|----------|-------------|
| `case5()` | 5-bus test system |
| `case9()` | IEEE 9-bus system |
| `case14()` | IEEE 14-bus system |

### Distribution Cases

| Function | Description |
|----------|-------------|
| `case_ieee13()` | IEEE 13-bus radial |
| `case_ieee33()` | IEEE 33-bus radial |

### Hybrid Cases

| Function | Description |
|----------|-------------|
| `case_hybrid_5ac3dc()` | 5 AC + 3 DC hybrid |

---

## Exception Types

| Export | Description |
|--------|-------------|
| `PowerCaseError` | Base exception type |
| `PowerCaseValidationError` | Validation error |
| `ForeignKeyError` | Referential integrity error |
| `SchemaError` | Schema mismatch error |

---

## Utils Compatibility

### JPC Types

| Export | Description |
|--------|-------------|
| `JPC` | Standard power case dict |
| `JPC_3ph` | Three-phase case dict |
| `JPC_sc` | Short-circuit case dict |
| `JPC_tp` | Transient case dict |
| `Fault_sc` | Fault specification |

### Key Lists

| Export | Description |
|--------|-------------|
| `JPC_KEYS` | Standard JPC keys |
| `JPC_3PH_KEYS` | Three-phase keys |
| `JPC_SC_KEYS` | Short-circuit keys |
| `JPC_TP_KEYS` | Transient keys |

---

## Validation Functions

| Function | Description |
|----------|-------------|
| `valid_buses(sys)` | Get valid bus indices |
| `active_buses(sys)` | Get in-service buses |
| `active_branches(sys)` | Get in-service branches |

---

## Index

### A
- `AbstractBranch`, `AbstractBus`, `AbstractComponent`
- `AbstractConverter`, `AbstractGenerator`, `AbstractLoad`
- `AbstractSchema`, `AbstractStorage`, `AbstractSwitch`
- `AC`, `ACBranch`, `ACBus`, `ACPowerCaseData`, `ACPowerSystem`
- `active_branches`, `active_buses`, `adjacency_list`

### B
- `Branch`, `BranchSchema`, `BusSchema`, `BusType`

### C
- `case14`, `case5`, `case9`, `case_hybrid_5ac3dc`
- `case_ieee13`, `case_ieee33`
- `Charger`, `ChargingStation`, `colidx`, `colnames`
- `component_names`, `component_table`, `ComponentMatrix`

### D
- `DC`, `DCBranch`, `DCBranchSchema`, `DCBus`, `DCBusSchema`
- `DCDCConverter`, `DCPowerCaseData`, `DCPowerSystem`
- `deepcopy_case`, `degree_vector`, `detect_islands`

### E
- `EnergyRouter`, `EnergyRouterPort`, `EVAggregator`
- `export_csv`, `ext2int`, `ExternalGrid`, `extract_islands`
- `extract_island_subsystem`

### F
- `Fault_sc`, `find_islands`, `find_islands_acdc`, `find_islands_dc`
- `FlexibleLoad`, `from_matrix`, `ForeignKeyError`

### G
- `Generator`, `GenCostSchema`, `GenModel`, `GenSchema`

### H
- `has_warnings`, `HybridPowerCaseData`, `HybridPowerSystem`

### I
- `InductionMotor`, `int2ext`, `is_connected`, `is_radial`
- `is_valid`, `IslandInfo`, `ISOLATED_BUS`

### J
- `JPC`, `JPC_3ph`, `JPC_3PH_KEYS`, `JPC_KEYS`
- `JPC_sc`, `JPC_SC_KEYS`, `JPC_tp`, `JPC_TP_KEYS`

### L
- `leaf_buses`, `Load`, `load_etap_csv`, `load_julia_case`
- `load_matpower`, `LoadSchema`

### M
- `merge_systems`, `Microgrid`, `MobileStorage`

### N
- `n_connected_components`, `nbranches`, `nbuses`, `ncols`
- `nconverters`, `ndcdc_converters`, `nenergy_routers`
- `nexternal_grids`, `ngenerators`, `nloads`, `NONE_MODEL`
- `nrows`, `nstatic_generators`, `nstorage`, `nswitches`
- `nvsc_converters`

### P
- `PIECEWISE_LINEAR`, `POLYNOMIAL_MODEL`, `PowerCaseData`
- `PowerCaseError`, `PowerCaseValidationError`, `POWER_LIMIT_LARGE`
- `PowerSystem`, `PQ_BUS`, `print_summary`, `PV_BUS`, `PVArray`, `PVSystem`

### R
- `rawdata`, `REF_BUS`, `renumber!`

### S
- `save_json`, `save_julia_case`, `schema_type`, `SchemaError`
- `slice_buses`, `StaticGenerator`, `Storage`, `StorageSchema`
- `summary_table`, `Switch`, `SwitchSchema`, `SystemKind`

### T
- `to_matrix`, `topology_summary`, `total_gen_capacity`, `total_load`
- `Transformer2W`, `Transformer3W`, `TransformerSchema`

### V
- `V2GService`, `valid_buses`, `validate_case`, `ValidationError`
- `VirtualPowerPlant`, `VM_MAX_REALISTIC`, `VM_MIN_REALISTIC`
- `VBOUND_MAX_REALISTIC`, `VSCConverter`, `VSCSchema`
