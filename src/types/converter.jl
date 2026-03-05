# ═══════════════════════════════════════════════════════════════════════════════
# VSCConverter, DCDCConverter, EnergyRouterPort, EnergyRouter
# ═══════════════════════════════════════════════════════════════════════════════

"""
    VSCConverter

Voltage-source converter (AC/DC bidirectional).
Conforms to component_models.tex specification.
"""
@kwdef struct VSCConverter <: AbstractConverter
    # Basic identification
    index::Int
    name::String                  = ""
    bus_ac::Int
    bus_dc::Int
    in_service::Bool              = true
    vsc_type::String              = "Two-Level"  # "Two-Level", "Three-Level", "MMC"
    
    # Rated parameters
    p_rated_mw::Float64           = 0.0       # Rated power (MW)
    vn_ac_kv::Float64             = 0.0       # AC rated voltage (kV)
    vn_dc_kv::Float64             = 0.0       # DC rated voltage (kV)
    
    # Operating state
    p_mw::Float64                 = 0.0       # AC side active power (MW)
    q_mvar::Float64               = 0.0       # AC side reactive power (MVAr)
    vm_ac_pu::Float64             = 1.0       # AC voltage magnitude (p.u.)
    vm_dc_pu::Float64             = 1.0       # DC voltage magnitude (p.u.)
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = -9999.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Efficiency
    eta::Float64                  = 0.98      # Conversion efficiency
    loss_percent::Float64         = 1.0       # Loss percentage
    loss_mw::Float64              = 0.0       # Actual loss (MW)
    
    # Control parameters
    controllable::Bool            = true
    control_mode::Symbol          = :pq       # :pq, :pv, :vdc_q, :droop
    p_set_mw::Float64             = 0.0       # Active power setpoint
    q_set_mvar::Float64           = 0.0       # Reactive power setpoint
    v_ac_set_pu::Float64          = 1.0       # AC voltage setpoint
    v_dc_set_pu::Float64          = 1.0       # DC voltage setpoint
    
    # Droop control parameters
    k_vdc::Float64                = 0.0       # DC voltage droop coefficient
    k_p::Float64                  = 0.0       # Active power droop coefficient
    k_q::Float64                  = 0.0       # Reactive power droop coefficient
    v_ref_pu::Float64             = 1.0       # Reference voltage (p.u.)
    f_ref_hz::Float64             = 50.0      # Reference frequency (Hz)
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0    # Mean time between failures (h)
    mttr_hours::Float64           = 24.0      # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
end


"""
    DCDCConverter

DC-DC converter for DC microgrids and HVDC systems.
Conforms to component_models.tex specification.
"""
@kwdef struct DCDCConverter <: AbstractConverter
    # Basic identification
    index::Int
    name::String                  = ""
    bus_in::Int                               # Input DC bus
    bus_out::Int                              # Output DC bus
    in_service::Bool              = true
    controllable::Bool            = true
    
    # Operating state
    v_in_pu::Float64              = 1.0       # Input voltage (p.u.)
    v_out_pu::Float64             = 1.0       # Output voltage (p.u.)
    p_in_mw::Float64              = 0.0       # Input power (MW)
    p_out_mw::Float64             = 0.0       # Output power (MW)
    
    # Setpoints
    p_ref_mw::Float64             = 0.0       # Power reference (MW)
    v_ref_pu::Float64             = 1.0       # Voltage reference (p.u.)
    
    # Rated parameters
    sn_mva::Float64               = 0.0       # Rated capacity (MVA)
    vn_in_kv::Float64             = 0.0       # Rated input voltage (kV)
    vn_out_kv::Float64            = 0.0       # Rated output voltage (kV)
    
    # Efficiency and losses
    eta::Float64                  = 0.98      # Conversion efficiency
    r_eq_pu::Float64              = 0.01      # Equivalent resistance (p.u.)
    f_switching_khz::Float64      = 10.0      # Switching frequency (kHz)
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = 0.0
    
    # Control mode
    control_mode::Symbol          = :power    # :power, :voltage, :droop
    k_droop::Float64              = 0.0       # Droop coefficient
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0
    mttr_hours::Float64           = 24.0
    t_scheduled_h::Float64        = 0.0
end


"""
    EnergyRouterPort

Single converter port of an energy router.
Conforms to component_models.tex RouterPort specification.
"""
@kwdef struct EnergyRouterPort <: AbstractConverter
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int                                  # Connected bus
    port_type::Symbol             = :ac       # :ac or :dc
    voltage_level_kv::Float64     = 0.0       # Voltage level (kV)
    
    # Operating state
    p_ac_mw::Float64              = 0.0       # AC active power (MW, + = out)
    q_ac_mvar::Float64            = 0.0       # AC reactive power (MVAr)
    v_ac_pu::Float64              = 1.0       # AC voltage (p.u.)
    p_dc_mw::Float64              = 0.0       # DC power (MW, + = out)
    v_dc_pu::Float64              = 1.0       # DC voltage (p.u.)
    phi_deg::Float64              = 0.0       # AC voltage phase angle (deg)
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = -9999.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Control
    control_mode::Symbol          = :pq       # :p, :q, :v, :pq, :pv, :vf
    p_set_mw::Float64             = 0.0
    q_set_mvar::Float64           = 0.0
    v_set_pu::Float64             = 1.0
    
    # Parent reference
    in_service::Bool              = true
    core_index::Int               = 0         # Parent router index
    side::Symbol                  = :primary  # :primary, :secondary
end


"""
    EnergyRouter

Multi-port energy router (aggregates EnergyRouterPorts).
Conforms to component_models.tex EnergyRouterConverter specification.
"""
@kwdef struct EnergyRouter <: AbstractConverter
    # Basic identification
    index::Int
    name::String                  = ""
    in_service::Bool              = true
    router_type::String           = "3-port"  # "3-port", "4-port", "Multi-port"
    
    # Port configuration
    num_ports::Int                = 3
    ports::Vector{EnergyRouterPort} = EnergyRouterPort[]
    
    # Rated parameters
    p_rated_mw::Float64           = 0.0       # Rated capacity (MW)
    vn_ac_kv::Float64             = 0.0       # AC rated voltage (kV)
    vn_dc_kv::Float64             = 0.0       # DC rated voltage (kV)
    
    # Loss parameters
    loss_percent::Float64         = 1.0       # Total loss percentage
    
    # Control
    control_mode::String          = "PowerDispatch"  # "PowerDispatch", "VoltageControl", "Droop"
    power_dispatch_strategy::String = "Proportional" # "Proportional", "Optimal", "Manual"
    
    # Power limits
    pmax_mw::Float64              = 9999.0
    pmin_mw::Float64              = -9999.0
    qmax_mvar::Float64            = 9999.0
    qmin_mvar::Float64            = -9999.0
    
    # Voltage limits
    vmax_pu::Float64              = 1.1
    vmin_pu::Float64              = 0.9
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0
    mttr_hours::Float64           = 24.0
    t_scheduled_h::Float64        = 0.0
    
    # Economic parameters
    investment_cost::Float64      = 0.0       # Investment cost (万元)
    operation_cost_per_mwh::Float64 = 0.0     # Operation cost (元/MWh)
    maintenance_cost_per_year::Float64 = 0.0  # Annual maintenance cost (万元)
end
