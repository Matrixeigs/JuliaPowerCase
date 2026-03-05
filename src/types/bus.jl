# ═══════════════════════════════════════════════════════════════════════════════
# Bus — AC/DC unified via phantom type parameter
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Bus{K<:SystemKind}

Network bus (node). Parametric on [`AC`](@ref) or [`DC`](@ref).
Conforms to component_models.tex Bus/BusDC specification.

# Fields
- `index::Int` — unique bus number
- `name::String` — descriptive name
- `base_kv::Float64` — base/rated voltage (kV)
- `bus_type::BusType` — PQ, PV, REF, or ISOLATED
- `vm_pu::Float64` — voltage magnitude (p.u.)
- `va_deg::Float64` — voltage angle (degrees)
- `pd_mw::Float64` — active load demand (MW)
- `qd_mvar::Float64` — reactive load demand (MVAr)
- `gs_mw::Float64` — shunt conductance (MW at V=1 p.u.)
- `bs_mvar::Float64` — shunt susceptance (MVAr at V=1 p.u.)
- `vmax_pu::Float64` — maximum voltage (p.u.)
- `vmin_pu::Float64` — minimum voltage (p.u.)
- `area::Int` — area number
- `zone::Int` — zone number
- `nc::Int` — number of customers (用户数)
- `omega::Float64` — importance weight (重要度)
- `is_load::Bool` — whether bus has load
- `in_service::Bool`
"""
@kwdef struct Bus{K<:SystemKind} <: AbstractBus
    # Basic identification
    index::Int
    name::String                  = ""
    bus_id::Int                   = 0         # External bus ID (for compatibility)
    in_service::Bool              = true
    
    # Electrical parameters
    base_kv::Float64              = 1.0       # Base/rated voltage (kV)
    bus_type::BusType             = PQ_BUS    # Bus type for power flow
    
    # Operating state
    vm_pu::Float64                = 1.0       # Voltage magnitude (p.u.)
    va_deg::Float64               = 0.0       # Voltage angle (degrees)
    
    # Voltage limits
    vmax_pu::Float64              = 1.1
    vmin_pu::Float64              = 0.9
    
    # Load at bus (convenience, also in Load struct)
    pd_mw::Float64                = 0.0       # Active load demand (MW)
    qd_mvar::Float64              = 0.0       # Reactive load demand (MVAr)
    
    # Shunt elements
    gs_mw::Float64                = 0.0       # Shunt conductance (MW at V=1)
    bs_mvar::Float64              = 0.0       # Shunt susceptance (MVAr at V=1)
    
    # Area/zone assignment
    area::Int                     = 1         # Area number
    zone::Int                     = 1         # Zone number
    carbon_area::Int              = 1         # Carbon accounting area
    carbon_zone::Int              = 1         # Carbon accounting zone
    
    # Resilience parameters (tex specification)
    nc::Int                       = 1         # Number of customers (用户数)
    omega::Float64                = 1.0       # Importance weight (重要度, 0-1)
    is_load::Bool                 = false     # Whether this is a load bus
end

"""AC bus — shorthand alias."""
const ACBus = Bus{AC}

"""DC bus — shorthand alias."""
const DCBus = Bus{DC}
