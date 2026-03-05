# ═══════════════════════════════════════════════════════════════════════════════
# PVArray, PVSystem — Photovoltaic renewable components
# ═══════════════════════════════════════════════════════════════════════════════

"""
    PVArray

DC-side photovoltaic array (panel model).
Conforms to component_models.tex PVArray specification.
"""
@kwdef struct PVArray <: AbstractGenerator
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int                                  # DC bus connection
    in_service::Bool              = true
    
    # Power output
    p_set_mw::Float64             = 0.0       # Power setpoint (MW)
    
    # Array configuration
    num_series::Int               = 1         # Modules in series
    num_parallel::Int             = 1         # Strings in parallel
    num_cells::Int                = 60        # Cells per module
    
    # Module electrical parameters (at STC)
    vmpp::Float64                 = 30.0      # MPP voltage (V)
    impp::Float64                 = 8.0       # MPP current (A)
    voc::Float64                  = 37.0      # Open-circuit voltage (V)
    isc::Float64                  = 8.5       # Short-circuit current (A)
    
    # Temperature coefficients
    α_isc::Float64                = 0.0004    # Isc temperature coefficient (%/°C)
    β_voc::Float64                = -0.003    # Voc temperature coefficient (%/°C)
    
    # Environmental conditions
    irradiance::Float64           = 1000.0    # Solar irradiance (W/m²)
    temperature::Float64          = 25.0      # Cell temperature (°C)
    
    # Reliability parameters
    mtbf_hours::Float64           = 87600.0   # Mean time between failures (h) ~10 years
    mttr_hours::Float64           = 24.0      # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
end


"""
    PVSystem

AC-connected PV system (array + inverter).
Conforms to component_models.tex ACPVSystem specification.
"""
@kwdef struct PVSystem <: AbstractGenerator
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int                                  # AC bus connection
    in_service::Bool              = true
    
    # Operating state
    p_mw::Float64                 = 0.0       # Active power output (MW)
    q_mvar::Float64               = 0.0       # Reactive power output (MVAr)
    vm_ac_pu::Float64             = 1.0       # AC voltage (p.u.)
    vm_dc_pu::Float64             = 1.0       # DC link voltage (p.u.)
    
    # Setpoints
    v_ac_set_pu::Float64          = 1.0       # AC voltage setpoint (p.u.)
    v_dc_set_pu::Float64          = 1.0       # DC voltage setpoint (p.u.)
    
    # Rated parameters
    sn_mva::Float64               = 0.0       # Rated apparent power (MVA)
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = 0.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Inverter parameters
    inverter_eff::Float64         = 0.98      # Inverter efficiency
    loss_percent::Float64         = 1.0       # Total loss percentage
    
    # Control
    control_mode::Symbol          = :pq       # :pq, :pv
    controllable::Bool            = true
    
    # Array configuration
    num_series::Int               = 1
    num_parallel::Int             = 1
    
    # Module parameters
    vmpp::Float64                 = 30.0
    impp::Float64                 = 8.0
    voc::Float64                  = 37.0
    isc::Float64                  = 8.5
    
    # Temperature coefficients
    α_isc::Float64                = 0.0004
    β_voc::Float64                = -0.003
    
    # Environmental conditions
    irradiance::Float64           = 1000.0
    temperature::Float64          = 25.0
    
    # System-level reliability
    mtbf_hours::Float64           = 8760.0    # System MTBF (h)
    mttr_hours::Float64           = 24.0      # System MTTR (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    
    # Panel reliability
    mtbf_panel_hours::Float64     = 175200.0  # Panel MTBF (h) ~20 years
    mttr_panel_hours::Float64     = 24.0      # Panel MTTR (h)
    
    # Inverter reliability
    mtbf_inverter_hours::Float64  = 43800.0   # Inverter MTBF (h) ~5 years
    mttr_inverter_hours::Float64  = 24.0      # Inverter MTTR (h)
end
