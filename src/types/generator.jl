# ═══════════════════════════════════════════════════════════════════════════════
# Generator, StaticGenerator, ExternalGrid
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Generator

Synchronous generator with economic dispatch, reliability, and short-circuit parameters.
Conforms to component_models.tex specification.
"""
@kwdef struct Generator <: AbstractGenerator
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    in_service::Bool              = true
    gen_type::Symbol              = :thermal  # :thermal, :hydro, :nuclear, :wind, :solar
    generator_type::String        = ""        # Specific type: "steam_turbine", "gas_turbine", "hydro", etc.
    
    # Operating state
    pg_mw::Float64                = 0.0       # Active power output (MW)
    qg_mvar::Float64              = 0.0       # Reactive power output (MVAr)
    vg_pu::Float64                = 1.0       # Voltage setpoint (p.u.)
    
    # Rated parameters
    mbase_mva::Float64            = 100.0     # Machine base (MVA)
    cos_phi::Float64              = 0.85      # Rated power factor
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = 0.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Control
    is_slack::Bool                = false
    controllable::Bool            = true
    
    # Ramp rates (MW/min)
    ramp_up_mw_min::Float64       = 9999.0    # Upward ramp rate
    ramp_down_mw_min::Float64     = 9999.0    # Downward ramp rate
    ramp_agc::Float64             = 9999.0    # AGC ramp rate
    ramp_10::Float64              = 9999.0    # 10-minute ramp
    ramp_30::Float64              = 9999.0    # 30-minute ramp
    
    # Minimum up/down time (hours)
    t_up_min_h::Float64           = 0.0       # Minimum uptime
    t_down_min_h::Float64         = 0.0       # Minimum downtime
    
    # Cost parameters
    cost_model::GenModel          = POLYNOMIAL_MODEL
    cost_startup::Float64         = 0.0       # Startup cost ($)
    cost_shutdown::Float64        = 0.0       # Shutdown cost ($)
    cost_coeffs::NTuple{3,Float64} = (0.0, 20.0, 0.0)  # c, b, a for a*P² + b*P + c
    
    # Emissions
    co2_emission_rate::Float64    = 0.0       # CO2 emission rate (kg/MWh)
    
    # Reliability
    mtbf_hours::Float64           = 8760.0    # Mean time between failures (h)
    mttr_hours::Float64           = 24.0      # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    forced_outage_rate::Float64   = 0.02      # Forced outage rate
    
    # Short-circuit parameters
    vn_kv::Float64                = 0.0       # Rated voltage (kV)
    xd_sub_pu::Float64            = 0.2       # Subtransient reactance (p.u.)
    ra_pu::Float64                = 0.0       # Armature resistance (p.u.)
    xd_pu::Float64                = 0.0       # Synchronous reactance (p.u.)
    xq_pu::Float64                = 0.0       # Q-axis synchronous reactance (p.u.)
    x0_pu::Float64                = 0.0       # Zero-sequence reactance (p.u.)
    x_r::Float64                  = 10.0      # X/R ratio
    
    # Sequence network parameters (for detailed short-circuit analysis)
    r1_pu::Float64                = 0.0       # Positive-sequence resistance (p.u.)
    x1_pu::Float64                = 0.2       # Positive-sequence reactance (p.u.)
    r2_pu::Float64                = 0.0       # Negative-sequence resistance (p.u.)
    x2_pu::Float64                = 0.2       # Negative-sequence reactance (p.u.)
    r0_pu::Float64                = 0.0       # Zero-sequence resistance (p.u.)
    # Note: x0_pu already defined above
    
    # Efficiency
    efficiency::Float64           = 0.95
end


"""
    StaticGenerator{K<:SystemKind}

Non-dispatchable distributed generator: PV, wind, CHP, etc.
Conforms to component_models.tex StaticGenerator specification.
"""
@kwdef struct StaticGenerator{K<:SystemKind} <: AbstractGenerator
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    in_service::Bool              = true
    sgen_type::Symbol             = :pv       # :pv, :wind, :chp, :fuel_cell, :diesel
    
    # Rated parameters
    p_rated_mw::Float64           = 0.0       # Rated active power (MW)
    q_rated_mvar::Float64         = 0.0       # Rated reactive power (MVAr)
    sn_mva::Float64               = 0.0       # Rated apparent power (MVA)
    
    # Operating state
    p_mw::Float64                 = 0.0       # Current active power (MW)
    q_mvar::Float64               = 0.0       # Current reactive power (MVAr)
    scaling::Float64              = 1.0       # Output scaling factor
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = 0.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Control parameters
    controllable::Bool            = false
    v_ref_pu::Float64             = 1.0       # Voltage reference (p.u.)
    k_p::Float64                  = 0.0       # Active power droop coefficient
    k_q::Float64                  = 0.0       # Reactive power droop coefficient
    f_ref_hz::Float64             = 50.0      # Frequency reference (Hz)
    
    # Short-circuit parameters
    k::Float64                    = 0.0       # Short-circuit impedance factor
    rx::Float64                   = 0.0       # R/X ratio
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0    # Mean time between failures (h)
    mttr_hours::Float64           = 24.0      # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    
    # Emissions
    fuel_type::String             = ""        # Fuel type (for CHP, diesel)
    co2_emission_rate::Float64    = 0.0       # CO2 emission rate (kg/MWh)
end


"""
    ExternalGrid

Utility grid interconnection (infinite bus) for short-circuit and power flow.
"""
@kwdef struct ExternalGrid <: AbstractGenerator
    index::Int
    name::String                  = ""
    bus::Int
    vm_pu::Float64                = 1.0
    va_deg::Float64               = 0.0
    s_sc_max_mva::Float64         = 9999.0
    s_sc_min_mva::Float64         = 9999.0
    rx_max::Float64               = 0.1
    rx_min::Float64               = 0.1
    r0x0_max::Float64             = 0.1
    x0x_max::Float64              = 1.0
    in_service::Bool              = true
    controllable::Bool            = true
    vn_kv::Float64                = 0.0
    ikq::Float64                  = 0.0
    x_r::Float64                  = 10.0
    r_pu::Float64                 = 0.0
    x_pu::Float64                 = 0.0
    r0_pu::Float64                = 0.0
    x0_pu::Float64                = 0.0
end
