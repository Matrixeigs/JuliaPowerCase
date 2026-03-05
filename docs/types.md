# Component Types Reference

JuliaPowerCase provides a comprehensive set of power system component types organized into a clear hierarchy.

## Type Hierarchy

```
AbstractComponent
├── AbstractBus          → Bus{AC}, Bus{DC}
├── AbstractBranch       → Branch{AC}, Branch{DC}
├── AbstractGenerator    → Generator, StaticGenerator, ExternalGrid
├── AbstractLoad         → Load, AsymmetricLoad, FlexibleLoad, InductionMotor
├── AbstractStorage      → Storage, MobileStorage
├── AbstractConverter    → VSCConverter, DCDCConverter, EnergyRouter
└── AbstractSwitch       → Switch
```

## Phantom Types

JuliaPowerCase uses phantom type tags to distinguish AC and DC components at compile time:

```julia
abstract type SystemKind end
struct AC <: SystemKind end
struct DC <: SystemKind end
```

This enables:
- Zero-cost type differentiation: `Bus{AC}` vs `Bus{DC}`
- Type-safe container parametrization: `PowerSystem{AC}`
- Compile-time dispatch for specialized algorithms

---

## Bus Types

### `Bus{K<:SystemKind}`

Network bus (node) for AC or DC systems.

```julia
@kwdef struct Bus{K<:SystemKind} <: AbstractBus
    # Identification
    index::Int
    name::String              = ""
    bus_id::Int               = 0
    in_service::Bool          = true
    
    # Electrical parameters
    base_kv::Float64          = 1.0       # Base voltage (kV)
    bus_type::BusType         = PQ_BUS    # PQ, PV, REF, or ISOLATED
    
    # Operating state
    vm_pu::Float64            = 1.0       # Voltage magnitude (p.u.)
    va_deg::Float64           = 0.0       # Voltage angle (degrees)
    
    # Voltage limits
    vmax_pu::Float64          = 1.1
    vmin_pu::Float64          = 0.9
    
    # Load at bus
    pd_mw::Float64            = 0.0       # Active load (MW)
    qd_mvar::Float64          = 0.0       # Reactive load (MVAr)
    
    # Shunt elements
    gs_mw::Float64            = 0.0       # Shunt conductance (MW at V=1)
    bs_mvar::Float64          = 0.0       # Shunt susceptance (MVAr at V=1)
    
    # Area/zone
    area::Int                 = 1
    zone::Int                 = 1
    
    # Resilience parameters
    nc::Int                   = 1         # Number of customers
    omega::Float64            = 1.0       # Importance weight (0-1)
    is_load::Bool             = false
end

# Type aliases
const ACBus = Bus{AC}
const DCBus = Bus{DC}
```

### BusType Enum

```julia
@enum BusType::Int32 begin
    PQ_BUS       = 1  # Load bus (P, Q specified)
    PV_BUS       = 2  # Generator bus (P, V specified)
    REF_BUS      = 3  # Slack/reference bus
    ISOLATED_BUS = 4  # Isolated bus
end
```

**Example:**
```julia
slack_bus = Bus{AC}(index=1, name="Slack", bus_type=REF_BUS, vm_pu=1.05)
load_bus = Bus{AC}(index=2, name="Load", bus_type=PQ_BUS, pd_mw=100.0)
dc_bus = Bus{DC}(index=1, name="DC-1", vm_pu=1.0)
```

---

## Branch Types

### `Branch{K<:SystemKind}`

Transmission line, cable, or transformer branch.

```julia
@kwdef struct Branch{K<:SystemKind} <: AbstractBranch
    # Identification
    index::Int
    name::String              = ""
    from_bus::Int
    to_bus::Int
    in_service::Bool          = true
    
    # Line parameters (p.u. on system base)
    r_pu::Float64             = 0.0       # Resistance
    x_pu::Float64             = 0.01      # Reactance
    b_pu::Float64             = 0.0       # Total charging susceptance
    
    # Ratings
    rate_a_mva::Float64       = 9999.0    # Normal rating
    rate_b_mva::Float64       = 9999.0    # Short-term rating
    rate_c_mva::Float64       = 9999.0    # Emergency rating
    
    # Transformer parameters
    tap_ratio::Float64        = 1.0       # Off-nominal turns ratio
    shift_deg::Float64        = 0.0       # Phase shift angle (degrees)
    tap_min::Float64          = 0.9
    tap_max::Float64          = 1.1
    tap_step::Float64         = 0.0125
    
    # Control
    tap_control::Bool         = false
    
    # Reliability
    failure_rate::Float64     = 0.001     # Failures per year
    repair_time_h::Float64    = 4.0       # Mean repair time (hours)
    length_km::Float64        = 0.0       # Line length (km)
end

const ACBranch = Branch{AC}
const DCBranch = Branch{DC}
```

**Example:**
```julia
line = Branch{AC}(
    index=1, from_bus=1, to_bus=2,
    r_pu=0.01, x_pu=0.1, b_pu=0.02,
    rate_a_mva=100.0
)

dc_cable = Branch{DC}(
    index=1, from_bus=1, to_bus=2,
    r_pu=0.005, rate_a_mva=200.0
)
```

---

## Generator Types

### `Generator`

Synchronous generator with dispatch and cost parameters.

```julia
@kwdef struct Generator <: AbstractGenerator
    # Identification
    index::Int
    name::String              = ""
    bus::Int
    in_service::Bool          = true
    controllable::Bool        = true
    
    # Operating point
    pg_mw::Float64            = 0.0       # Active power output
    qg_mvar::Float64          = 0.0       # Reactive power output
    vg_pu::Float64            = 1.0       # Voltage setpoint
    
    # Active power limits
    pmax_mw::Float64          = 9999.0
    pmin_mw::Float64          = 0.0
    
    # Reactive power limits
    qmax_mvar::Float64        = 9999.0
    qmin_mvar::Float64        = -9999.0
    
    # Cost parameters
    cost_model::GenModel      = POLYNOMIAL_MODEL
    startup_cost::Float64     = 0.0
    shutdown_cost::Float64    = 0.0
    cost_coeffs::Vector{Float64} = [0.0, 1.0, 0.0]  # c0, c1, c2
    
    # Dynamics
    mbase_mva::Float64        = 100.0     # Machine base
    ramp_rate_mw_min::Float64 = 9999.0    # Ramp rate (MW/min)
    min_up_time_h::Float64    = 0.0
    min_down_time_h::Float64  = 0.0
end
```

### `StaticGenerator{K}`

Static generator (PV, wind, CHP) with AC/DC parametrization.

```julia
@kwdef struct StaticGenerator{K<:SystemKind} <: AbstractGenerator
    index::Int
    name::String              = ""
    bus::Int
    in_service::Bool          = true
    sgen_type::Symbol         = :pv       # :pv, :wind, :chp, :fuel_cell
    
    # Power output
    p_mw::Float64             = 0.0
    q_mvar::Float64           = 0.0
    
    # Limits
    pmax_mw::Float64          = 0.0
    pmin_mw::Float64          = 0.0
    qmax_mvar::Float64        = 0.0
    qmin_mvar::Float64        = 0.0
    
    # Scaling factor
    scaling::Float64          = 1.0
end
```

### `ExternalGrid`

Connection to an external grid (infinite bus).

```julia
@kwdef struct ExternalGrid <: AbstractGenerator
    index::Int
    name::String              = ""
    bus::Int
    in_service::Bool          = true
    
    vm_pu::Float64            = 1.0       # Voltage magnitude
    va_deg::Float64           = 0.0       # Voltage angle
    
    # Short-circuit parameters
    sk_max_mva::Float64       = 9999.0    # Max short-circuit power
    sk_min_mva::Float64       = 0.0       # Min short-circuit power
    rx_ratio::Float64         = 0.0       # R/X ratio
end
```

**Example:**
```julia
gen = Generator(
    index=1, bus=1, pg_mw=100.0,
    pmax_mw=200.0, cost_coeffs=[0.0, 20.0, 0.01]
)

pv = StaticGenerator{AC}(
    index=1, bus=5, sgen_type=:pv,
    p_mw=50.0, pmax_mw=60.0
)
```

---

## Converter Types

### `VSCConverter`

Voltage-source converter for AC/DC coupling.

```julia
@kwdef struct VSCConverter <: AbstractConverter
    # Identification
    index::Int
    name::String              = ""
    bus_ac::Int               # Connected AC bus
    bus_dc::Int               # Connected DC bus
    in_service::Bool          = true
    vsc_type::String          = "Two-Level"  # "Two-Level", "MMC"
    
    # Rated parameters
    p_rated_mw::Float64       = 0.0
    vn_ac_kv::Float64         = 0.0
    vn_dc_kv::Float64         = 0.0
    
    # Operating state
    p_mw::Float64             = 0.0       # AC side active power
    q_mvar::Float64           = 0.0       # AC side reactive power
    vm_ac_pu::Float64         = 1.0
    vm_dc_pu::Float64         = 1.0
    
    # Power limits
    pmax_mw::Float64          = 9999.0
    pmin_mw::Float64          = -9999.0
    qmax_mvar::Float64        = 9999.0
    qmin_mvar::Float64        = -9999.0
    
    # Efficiency
    eta::Float64              = 0.98      # Conversion efficiency
    loss_percent::Float64     = 1.0
    loss_mw::Float64          = 0.0
    
    # Control
    control_mode::Symbol      = :pq       # :pq, :pv, :vdc_q, :droop
    p_set_mw::Float64         = 0.0
    q_set_mvar::Float64       = 0.0
    v_ac_set_pu::Float64      = 1.0
    v_dc_set_pu::Float64      = 1.0
    
    # Droop parameters
    k_vdc::Float64            = 0.0       # DC voltage droop
    k_p::Float64              = 0.0       # Active power droop
    k_q::Float64              = 0.0       # Reactive power droop
end
```

### Control Modes

| Mode | Description | Controlled Variables |
|------|-------------|---------------------|
| `:pq` | Power control | P_ac, Q_ac fixed |
| `:pv` | P-V control | P_ac, V_ac fixed |
| `:vdc_q` | DC voltage control | V_dc, Q_ac fixed |
| `:droop` | Droop control | V_dc via droop |

### `DCDCConverter`

DC-DC converter for voltage level matching.

```julia
@kwdef struct DCDCConverter <: AbstractConverter
    index::Int
    name::String              = ""
    bus_in::Int               # Input DC bus
    bus_out::Int              # Output DC bus
    in_service::Bool          = true
    
    # Operating state
    v_in_pu::Float64          = 1.0
    v_out_pu::Float64         = 1.0
    p_in_mw::Float64          = 0.0
    p_out_mw::Float64         = 0.0
    
    # Setpoints
    p_ref_mw::Float64         = 0.0
    v_ref_pu::Float64         = 1.0
    
    # Efficiency
    eta::Float64              = 0.98
    
    # Control
    control_mode::Symbol      = :power    # :power, :voltage, :droop
    k_droop::Float64          = 0.0
end
```

### `EnergyRouter`

Multi-port energy router (aggregates ports).

```julia
@kwdef struct EnergyRouter <: AbstractConverter
    index::Int
    name::String              = ""
    in_service::Bool          = true
    router_type::String       = "3-port"
    
    num_ports::Int            = 3
    ports::Vector{EnergyRouterPort} = EnergyRouterPort[]
    
    p_rated_mw::Float64       = 0.0
    loss_percent::Float64     = 1.0
end
```

**Example:**
```julia
vsc = VSCConverter(
    index=1, bus_ac=2, bus_dc=1,
    p_set_mw=50.0, q_set_mvar=10.0,
    control_mode=:pq, eta=0.98
)

dcdc = DCDCConverter(
    index=1, bus_in=1, bus_out=2,
    p_ref_mw=100.0, control_mode=:power
)
```

---

## Load Types

### `Load{K}`

General load model with scaling capability.

```julia
@kwdef struct Load{K<:SystemKind} <: AbstractLoad
    index::Int
    name::String              = ""
    bus::Int
    in_service::Bool          = true
    
    # Power demand
    p_mw::Float64             = 0.0       # Active power
    q_mvar::Float64           = 0.0       # Reactive power
    
    # Scaling
    scaling::Float64          = 1.0       # Scale factor (0-1)
    controllable::Bool        = false
    
    # Load type
    load_type::Symbol         = :constant_power  # :constant_power, :constant_impedance, :zip
    
    # Priority
    priority::Int             = 3         # 1 = critical, 3 = normal
end
```

### `FlexibleLoad{K}`

Demand response capable load.

```julia
@kwdef struct FlexibleLoad{K<:SystemKind} <: AbstractLoad
    index::Int
    name::String              = ""
    bus::Int
    in_service::Bool          = true
    
    p_mw::Float64             = 0.0
    q_mvar::Float64           = 0.0
    
    # Flexibility
    flex_up_mw::Float64       = 0.0       # Upward flexibility
    flex_down_mw::Float64     = 0.0       # Downward flexibility
    response_time_s::Float64  = 0.0       # Response time
    
    # Scheduling
    scheduled::Bool           = false
    schedule_profile::Vector{Float64} = Float64[]
end
```

---

## Storage Types

### `Storage{K}`

Energy storage device (battery, flywheel).

```julia
@kwdef struct Storage{K<:SystemKind} <: AbstractStorage
    index::Int
    name::String              = ""
    bus::Int
    in_service::Bool          = true
    
    # Power ratings
    p_mw::Float64             = 0.0       # Current power (+ = discharge)
    pmax_mw::Float64          = 0.0       # Max discharge power
    pmin_mw::Float64          = 0.0       # Max charge power (negative)
    
    # Energy capacity
    e_mwh::Float64            = 0.0       # Current energy
    emax_mwh::Float64         = 0.0       # Max energy capacity
    emin_mwh::Float64         = 0.0       # Min energy (SOC floor)
    
    # Efficiency
    eta_charge::Float64       = 0.95
    eta_discharge::Float64    = 0.95
    
    # State
    soc::Float64              = 0.5       # State of charge (0-1)
    controllable::Bool        = true
end
```

---

## Transformer Types

### `Transformer2W`

Two-winding transformer with tap control.

```julia
@kwdef struct Transformer2W <: AbstractBranch
    index::Int
    name::String              = ""
    hv_bus::Int               # High-voltage bus
    lv_bus::Int               # Low-voltage bus
    in_service::Bool          = true
    
    # Ratings
    sn_mva::Float64           = 0.0       # Rated power
    vn_hv_kv::Float64         = 0.0       # HV rated voltage
    vn_lv_kv::Float64         = 0.0       # LV rated voltage
    
    # Parameters
    vk_percent::Float64       = 0.0       # Short-circuit voltage
    vkr_percent::Float64      = 0.0       # Resistive short-circuit voltage
    pfe_kw::Float64           = 0.0       # No-load losses
    i0_percent::Float64       = 0.0       # No-load current
    
    # Tap changer
    tap_pos::Int              = 0         # Current tap position
    tap_min::Int              = -10
    tap_max::Int              = 10
    tap_step_percent::Float64 = 1.25
    tap_side::Symbol          = :hv       # :hv or :lv
end
```

---

## Switch Types

### `Switch`

Circuit breaker, switch, or fuse.

```julia
@kwdef struct Switch <: AbstractSwitch
    index::Int
    name::String              = ""
    from_bus::Int
    to_bus::Int
    
    closed::Bool              = true      # Switch state
    switch_type::Symbol       = :cb       # :cb, :ls, :fuse
    
    # Ratings
    i_rated_ka::Float64       = 0.0       # Rated current
    i_breaking_ka::Float64    = 0.0       # Breaking current
    
    # Reliability
    mtbf_hours::Float64       = 87600.0
    operation_time_ms::Float64 = 50.0
end
```

---

## Usage Patterns

### Creating Components with Keyword Constructor

```julia
# All fields have defaults, only specify what you need
bus = Bus{AC}(index=1, name="Main", bus_type=REF_BUS)
gen = Generator(index=1, bus=1, pg_mw=100.0, pmax_mw=200.0)
line = Branch{AC}(index=1, from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.1)
```

### Type-Safe Operations

```julia
# Compile-time error: cannot mix AC and DC
ac_bus = Bus{AC}(index=1)
# dc_system.buses = [ac_bus]  # Error: type mismatch

# Safe: parametric dispatch
function process(bus::Bus{AC})
    # AC-specific logic
end

function process(bus::Bus{DC})
    # DC-specific logic
end
```

### Querying Fields

```julia
# Direct field access
bus.vm_pu
bus.bus_type

# Pattern matching on bus type
if bus.bus_type == REF_BUS
    println("Reference bus")
elseif bus.bus_type == PV_BUS
    println("Generator bus")
end
```
