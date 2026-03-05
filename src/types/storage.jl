# ═══════════════════════════════════════════════════════════════════════════════
# Storage, MobileStorage
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Storage{K<:SystemKind}

Battery energy storage system. Parametric on `AC`/`DC`.
Conforms to component_models.tex specification with full reliability and lifecycle modeling.
"""
@kwdef struct Storage{K<:SystemKind} <: AbstractStorage
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    in_service::Bool              = true
    storage_type::Symbol          = :li_ion   # :li_ion, :lead_acid, :flow, :supercap
    
    # Power parameters
    p_rated_mw::Float64           = 0.0       # Rated power (MW)
    p_mw::Float64                 = 0.0       # Current active power (MW, + discharge, - charge)
    q_mvar::Float64               = 0.0       # Current reactive power (MVAr)
    pmax_mw::Float64              = 9999.0    # Max discharge power (MW)
    pmin_mw::Float64              = -9999.0   # Max charge power (MW, negative)
    qmax_mvar::Float64            = 9999.0    # Max reactive power (MVAr)
    qmin_mvar::Float64            = -9999.0   # Min reactive power (MVAr)
    
    # Energy parameters
    e_rated_mwh::Float64          = 0.0       # Rated energy capacity (MWh)
    e_mwh::Float64                = 0.0       # Current stored energy (MWh)
    soc_init::Float64             = 0.5       # Initial SOC (0–1)
    soc_min::Float64              = 0.1       # Min SOC (0–1)
    soc_max::Float64              = 0.9       # Max SOC (0–1)
    
    # Efficiency parameters
    eta_charge::Float64           = 0.95      # Charging efficiency
    eta_discharge::Float64        = 0.95      # Discharging efficiency
    eta_roundtrip::Float64        = 0.92      # Round-trip efficiency
    
    # Control parameters
    controllable::Bool            = true
    control_mode::Symbol          = :pq       # :pq, :vdc, :droop, :constant_power
    
    # System-level reliability
    mtbf_hours::Float64           = 8760.0    # Mean time between failures (h)
    mttr_hours::Float64           = 24.0      # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    
    # Battery subsystem reliability
    mtbf_battery_hours::Float64   = 43800.0   # Battery MTBF (h) ~5 years
    mttr_battery_hours::Float64   = 168.0     # Battery MTTR (h) ~1 week
    
    # PCS (Power Conversion System) reliability
    mtbf_pcs_hours::Float64       = 17520.0   # PCS MTBF (h) ~2 years
    mttr_pcs_hours::Float64       = 24.0      # PCS MTTR (h)
    
    # BMS (Battery Management System) reliability
    mtbf_bms_hours::Float64       = 87600.0   # BMS MTBF (h) ~10 years
    mttr_bms_hours::Float64       = 4.0       # BMS MTTR (h)
    
    # Lifecycle parameters
    n_cycle::Int                  = 6000      # Rated cycle life
    l_calendar_years::Float64     = 15.0      # Calendar life (years)
    eol_percent::Float64          = 80.0      # End-of-life SOH threshold (%)
    soh::Float64                  = 100.0     # Current state of health (%)
    soh_cycle::Float64            = 100.0     # Cycle degradation SOH (%)
    soh_calendar::Float64         = 100.0     # Calendar degradation SOH (%)
    cycles_used::Int              = 0         # Accumulated cycle count
end


"""
    MobileStorage

Transportable battery (truck, container, ship).
Inherits Storage parameters plus mobility-specific fields.
"""
@kwdef struct MobileStorage <: AbstractStorage
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int                      = 0         # Current connected bus (0 if not connected)
    in_service::Bool              = true
    storage_type::Symbol          = :container  # :container, :truck, :ship
    
    # Power parameters (same as Storage)
    p_rated_mw::Float64           = 0.0
    p_mw::Float64                 = 0.0
    q_mvar::Float64               = 0.0
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = -9999.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Energy parameters
    e_rated_mwh::Float64          = 0.0
    e_mwh::Float64                = 0.0
    soc_init::Float64             = 0.5
    soc_min::Float64              = 0.1
    soc_max::Float64              = 0.9
    
    # Efficiency
    eta_charge::Float64           = 0.95
    eta_discharge::Float64        = 0.92
    
    # Control
    controllable::Bool            = true
    control_mode::Symbol          = :pq
    
    # System reliability (same as Storage)
    mtbf_hours::Float64           = 8760.0
    mttr_hours::Float64           = 24.0
    t_scheduled_h::Float64        = 0.0
    mtbf_battery_hours::Float64   = 43800.0
    mttr_battery_hours::Float64   = 168.0
    mtbf_pcs_hours::Float64       = 17520.0
    mttr_pcs_hours::Float64       = 24.0
    mtbf_bms_hours::Float64       = 87600.0
    mttr_bms_hours::Float64       = 4.0
    
    # Lifecycle
    n_cycle::Int                  = 6000
    l_calendar_years::Float64     = 15.0
    eol_percent::Float64          = 80.0
    soh::Float64                  = 100.0
    soh_cycle::Float64            = 100.0
    soh_calendar::Float64         = 100.0
    cycles_used::Int              = 0
    
    # Mobility parameters (tex specification)
    is_mobile::Bool               = true
    current_location::String      = ""        # Current physical location
    target_bus::Int               = 0         # Target bus for dispatch
    e_consumption_mwh_km::Float64 = 0.001     # Energy consumption per km (MWh/km)
    max_travel_distance_km::Float64 = 500.0   # Maximum travel distance (km)
    arrival_time::Float64         = 0.0       # Arrival time (hours from t=0)
    departure_time::Float64       = 24.0      # Departure time (hours from t=0)
    t_stay_min_h::Float64         = 1.0       # Minimum stay time (h)
    t_stay_max_h::Float64         = 24.0      # Maximum stay time (h)
    
    # Vehicle reliability
    mtbf_vehicle_hours::Float64   = 8760.0    # Vehicle MTBF (h)
    mttr_vehicle_hours::Float64   = 24.0      # Vehicle MTTR (h)
    
    # Status
    status::Symbol                = :available  # :available, :in_transit, :connected, :charging, :discharging
    owner::String                 = ""
end
