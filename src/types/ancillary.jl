# ═══════════════════════════════════════════════════════════════════════════════
# Ancillary — VPP, Microgrid, EV, Carbon
# Conforms to component_models.tex specifications
# ═══════════════════════════════════════════════════════════════════════════════

using Dates

# ── Electric Vehicle Infrastructure ──────────────────────────────────────────

"""
    ChargingStation

EV charging station (aggregates chargers).
Conforms to component_models.tex ChargingStation specification.
"""
@kwdef struct ChargingStation <: AbstractComponent
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    location::String              = ""
    in_service::Bool              = true
    
    # Charger configuration
    n_fast::Int                   = 0         # Number of DC fast chargers
    n_slow::Int                   = 0         # Number of AC slow chargers
    num_chargers::Int             = 1         # Total chargers (legacy)
    
    # Power parameters
    p_fast_max_kw::Float64        = 150.0     # Fast charger max power (kW each)
    p_slow_max_kw::Float64        = 22.0      # Slow charger max power (kW each)
    max_power_kw::Float64         = 150.0     # Total max power (legacy)
    
    # Load characteristics
    simultaneity_factor::Float64  = 0.7       # Simultaneity factor (0-1)
    power_factor::Float64         = 0.98      # Power factor
    utilization_rate::Float64     = 0.5       # Average utilization (0-1)
    
    # Real-time state
    p_total_kw::Float64           = 0.0       # Current total active power (kW)
    q_total_kvar::Float64         = 0.0       # Current total reactive power (kVAr)
    n_cars::Int                   = 0         # Current vehicles charging
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0    # Mean time between failures (h)
    mttr_hours::Float64           = 24.0      # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    
    # Operator
    operator::String              = ""
end


"""
    Charger

Individual EV charger.
Conforms to component_models.tex Charger specification.
"""
@kwdef struct Charger <: AbstractComponent
    # Basic identification
    index::Int
    name::String                  = ""
    station_id::Int
    charger_type::Symbol          = :dc_fast  # :ac_l1, :ac_l2, :dc_fast, :ultra_fast
    connector_type::String        = "CCS"
    
    # Status
    in_service::Bool              = true
    status::Symbol                = :idle     # :idle, :charging, :discharging, :fault
    
    # Power capability
    p_ev_kw::Float64              = 0.0       # Actual power (kW, + charge, - discharge)
    p_rated_kw::Float64           = 150.0     # Rated power (kW)
    p_ch_max_kw::Float64          = 150.0     # Max charging power (kW)
    p_ch_min_kw::Float64          = 0.0       # Min charging power (kW)
    p_dis_max_kw::Float64         = 0.0       # Max discharging power (kW)
    p_dis_min_kw::Float64         = 0.0       # Min discharging power (kW)
    max_power_kw::Float64         = 150.0     # Legacy field
    min_power_kw::Float64         = 0.0       # Legacy field
    
    # Efficiency
    eta::Float64                  = 0.95      # Conversion efficiency
    
    # V2G capability
    v2g_capable::Bool             = false
    p_discharge_max_kw::Float64   = 0.0       # Max V2G discharge power (kW)
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0
    mttr_hours::Float64           = 24.0
    t_scheduled_h::Float64        = 0.0
    
    # Availability
    availability::Float64         = 1.0
end


"""
    EVAggregator

Fleet of EVs participating in grid services.
"""
@kwdef struct EVAggregator <: AbstractComponent
    index::Int
    name::String                  = ""
    num_evs::Int
    total_capacity_mwh::Float64
    max_power_mw::Float64
    control_strategy::Symbol      = :price_responsive
    service_area::String          = ""
    operator::String              = ""
end


"""
    V2GService

Vehicle-to-grid service contract.
"""
@kwdef struct V2GService <: AbstractComponent
    index::Int
    aggregator_id::Int
    service_type::Symbol          = :frequency_regulation
    start_time::DateTime          = DateTime(2024, 1, 1)
    end_time::DateTime            = DateTime(2024, 12, 31)
    capacity_mw::Float64          = 0.0
    energy_mwh::Float64           = 0.0
    price_per_mwh::Float64        = 0.0
    grid_area::String             = ""
    reliability_percent::Float64  = 95.0
end


# ── Virtual Power Plant & Microgrid ──────────────────────────────────────────

"""
    VirtualPowerPlant

Aggregated DERs acting as a single dispatchable resource.
Conforms to component_models.tex VirtualPowerPlant specification.
"""
@kwdef struct VirtualPowerPlant <: AbstractComponent
    # Basic identification
    index::Int
    name::String                  = ""
    description::String           = ""
    aggregation_bus::Int          = 0         # Aggregation bus index
    service_area::String          = ""        # Service area identifier
    operator::String              = ""        # Operator name
    in_service::Bool              = true
    
    # Resource counts - DG
    n_pv_systems::Int             = 0         # PV systems count
    n_wind_turbines::Int          = 0         # Wind turbines count
    n_chp_units::Int              = 0         # CHP units count
    n_biomass_units::Int          = 0         # Biomass units count
    
    # Resource counts - Storage
    n_battery_systems::Int        = 0         # Battery systems count
    n_ev_chargers::Int            = 0         # EV chargers count
    n_thermal_storage::Int        = 0         # Thermal storage count
    
    # Resource counts - Loads
    n_controllable_loads::Int     = 0         # Controllable loads count
    n_hvac_systems::Int           = 0         # HVAC systems count
    n_industrial_loads::Int       = 0         # Industrial loads count
    
    # Generation capacity
    p_pv_sum_mw::Float64          = 0.0       # Total PV capacity (MW)
    p_wind_sum_mw::Float64        = 0.0       # Total wind capacity (MW)
    p_chp_sum_mw::Float64         = 0.0       # Total CHP capacity (MW)
    p_generation_sum_mw::Float64  = 0.0       # Total generation capacity (MW)
    
    # Storage capacity
    e_battery_sum_mwh::Float64    = 0.0       # Total battery energy (MWh)
    p_battery_sum_mw::Float64     = 0.0       # Total battery power (MW)
    e_ev_sum_mwh::Float64         = 0.0       # Total EV energy (MWh)
    e_storage_sum_mwh::Float64    = 0.0       # Total storage energy (MWh)
    
    # Load capacity
    p_load_controllable_mw::Float64 = 0.0     # Controllable load capacity (MW)
    p_load_sum_mw::Float64        = 0.0       # Total load (MW)
    
    # Operating state
    p_output_mw::Float64          = 0.0       # Current output (MW)
    p_consumption_mw::Float64     = 0.0       # Current consumption (MW)
    p_net_mw::Float64             = 0.0       # Net power (MW, + = generation)
    q_output_mvar::Float64        = 0.0       # Reactive output (MVAr)
    
    # Dispatch capability
    pmax_mw::Float64              = 9999.0    # Max output (MW)
    pmin_mw::Float64              = -9999.0   # Min output (MW)
    ramp_up_max_mw_min::Float64   = 9999.0    # Max up ramp (MW/min)
    ramp_down_max_mw_min::Float64 = 9999.0    # Max down ramp (MW/min)
    
    # Regulation capability
    p_regulation_up_mw::Float64   = 0.0       # Up-regulation capacity (MW)
    p_regulation_down_mw::Float64 = 0.0       # Down-regulation capacity (MW)
    
    # Legacy fields
    control_area::String          = ""
    capacity_mw::Float64          = 0.0
    energy_mwh::Float64           = 0.0
    response_time_s::Float64      = 60.0
    ramp_rate_mw_min::Float64     = 1.0
    availability_percent::Float64 = 95.0
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0
    mttr_hours::Float64           = 24.0
    t_scheduled_h::Float64        = 0.0
end


"""
    Microgrid

Self-contained power system that can operate grid-connected or islanded.
Conforms to component_models.tex Microgrid specification.
"""
@kwdef struct Microgrid <: AbstractComponent
    # Basic identification
    index::Int
    name::String                  = ""
    description::String           = ""
    control_area::String          = ""
    in_service::Bool              = true
    
    # Network topology
    pcc_bus::Int                  = 0         # Point of common coupling bus
    internal_buses::Vector{Int}   = Int[]     # Internal bus indices
    
    # Operating mode
    operating_mode::String        = "grid-connected"  # "grid-connected", "islanded", "transition"
    islanding_capability::Bool    = true      # Can operate islanded
    auto_reconnection::Bool       = true      # Automatic reconnection capability
    
    # Power exchange limits
    p_exchange_max_mw::Float64    = 9999.0    # Max exchange power (MW)
    p_exchange_min_mw::Float64    = -9999.0   # Min exchange power (MW)
    p_import_max_mw::Float64      = 9999.0    # Max import power (MW)
    p_export_max_mw::Float64      = 9999.0    # Max export power (MW)
    p_exchange_mw::Float64        = 0.0       # Current exchange (MW, + = import)
    
    # Internal resource summary
    total_generation_mw::Float64  = 0.0       # Total generation capacity (MW)
    total_storage_mwh::Float64    = 0.0       # Total storage capacity (MWh)
    total_load_mw::Float64        = 0.0       # Total load (MW)
    total_dg_capacity_mw::Float64 = 0.0       # Total DG capacity (MW)
    total_diesel_capacity_mw::Float64 = 0.0   # Total diesel capacity (MW)
    
    # Control parameters
    f_set_hz::Float64             = 50.0      # Frequency setpoint (Hz)
    v_set_pu::Float64             = 1.0       # Voltage setpoint (p.u.)
    p_set_mw::Float64             = 0.0       # Power setpoint (MW)
    k_droop::Float64              = 0.05      # Droop coefficient
    
    # Protection limits
    f_max_hz::Float64             = 51.0      # Max frequency (Hz)
    f_min_hz::Float64             = 49.0      # Min frequency (Hz)
    v_max_pu::Float64             = 1.1       # Max voltage (p.u.)
    v_min_pu::Float64             = 0.9       # Min voltage (p.u.)
    
    # Legacy fields
    capacity_mw::Float64          = 0.0
    peak_load_mw::Float64         = 0.0
    duration_h::Float64           = 4.0
    area::Int                     = 1
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0
    mttr_hours::Float64           = 24.0
    t_scheduled_h::Float64        = 0.0
end


# ── Carbon Accounting ────────────────────────────────────────────────────────

"""
    CarbonTimeSeries

Time-varying carbon intensity data.
"""
@kwdef struct CarbonTimeSeries <: AbstractComponent
    index::Int
    timestamp::DateTime
    grid_carbon_intensity_kgCO2e_per_MWh::Float64 = 0.0
    renewable_carbon_intensity_kgCO2e_per_MWh::Float64 = 0.0
    storage_carbon_intensity_kgCO2e_per_MWh::Float64 = 0.0
end


"""
    CarbonScenario

Carbon emission scenario parameters.
"""
@kwdef struct CarbonScenario <: AbstractComponent
    index::Int
    name::String                  = ""
    description::String           = ""
    year::Int                     = 2030
    grid_carbon_intensity_kgCO2e_per_MWh::Float64 = 400.0
    renewable_penetration_percent::Float64 = 50.0
    ev_adoption_percent::Float64  = 30.0
    storage_adoption_percent::Float64 = 20.0
end


"""
    EquipmentCarbon

Embodied and operational carbon for equipment.
"""
@kwdef struct EquipmentCarbon <: AbstractComponent
    index::Int
    element_type::Symbol          = :generator
    element_id::Int
    carbon_embodied_kgCO2e::Float64 = 0.0
    carbon_operational_kgCO2e_per_year::Float64 = 0.0
    lifetime_years::Int           = 25
    manufacturing_date::Date      = Date(2020, 1, 1)
    installation_date::Date       = Date(2020, 6, 1)
    recycling_rate_percent::Float64 = 80.0
end
