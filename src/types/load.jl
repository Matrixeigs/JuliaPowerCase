# ═══════════════════════════════════════════════════════════════════════════════
# Load, AsymmetricLoad, FlexibleLoad, InductionMotor
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Load{K<:SystemKind}

Static load with ZIP model composition.
Conforms to component_models.tex Load/LumpedLoad/LoadDC specification.
"""
@kwdef struct Load{K<:SystemKind} <: AbstractLoad
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    in_service::Bool              = true
    load_type::Symbol             = :wye      # :wye, :delta (connection type)
    
    # Power demand (rated values)
    p_rated_mw::Float64           = 0.0       # Rated active power (MW)
    q_rated_mvar::Float64         = 0.0       # Rated reactive power (MVAr)
    
    # Operating values
    p_mw::Float64                 = 0.0       # Current active power (MW)
    q_mvar::Float64               = 0.0       # Current reactive power (MVAr)
    scaling::Float64              = 1.0       # Load scaling factor
    
    # ZIP model coefficients (must sum to 100)
    const_z_percent::Float64      = 0.0       # Constant impedance (%)
    const_i_percent::Float64      = 0.0       # Constant current (%)
    const_p_percent::Float64      = 100.0     # Constant power (%)
    
    # Control and priority (tex specification)
    controllable::Bool            = false     # Whether load is controllable/curtailable
    priority::Int                 = 3         # Load priority (1=highest, 5=lowest)
    
    # Motor load parameters (for short-circuit)
    sn_mva::Float64               = 0.0       # Motor rated capacity (MVA)
    vn_kv::Float64                = 0.0       # Motor rated voltage (kV)
    motor_percent::Float64        = 0.0       # Motor load percentage (%)
    lrc::Float64                  = 0.0       # Locked rotor current ratio
    x_r::Float64                  = 0.0       # X/R ratio
    x_sub_pu::Float64             = 0.0       # Subtransient reactance (p.u.)
    tdp::Float64                  = 0.0       # Stator transient time constant (s)
end


"""
    AsymmetricLoad

Three-phase unbalanced load.
Conforms to component_models.tex AsymmetricLoad specification.
"""
@kwdef struct AsymmetricLoad <: AbstractLoad
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    in_service::Bool              = true
    
    # Connection type
    connection::String            = "Wye"     # "Wye" or "Delta"
    grounded::Bool                = true      # Grounding for Wye connection
    load_type::Symbol             = :wye      # Legacy field for compatibility
    
    # Per-phase power demands (rated values)
    pa_rated_mw::Float64          = 0.0       # Phase A rated active power (MW)
    qa_rated_mvar::Float64        = 0.0       # Phase A rated reactive power (MVAr)
    pb_rated_mw::Float64          = 0.0       # Phase B rated active power (MW)
    qb_rated_mvar::Float64        = 0.0       # Phase B rated reactive power (MVAr)
    pc_rated_mw::Float64          = 0.0       # Phase C rated active power (MW)
    qc_rated_mvar::Float64        = 0.0       # Phase C rated reactive power (MVAr)
    
    # Operating values
    pa_mw::Float64                = 0.0
    qa_mvar::Float64              = 0.0
    pb_mw::Float64                = 0.0
    qb_mvar::Float64              = 0.0
    pc_mw::Float64                = 0.0
    qc_mvar::Float64              = 0.0
    scaling::Float64              = 1.0
    
    # ZIP model coefficients
    const_z_percent::Float64      = 0.0
    const_i_percent::Float64      = 0.0
    const_p_percent::Float64      = 100.0
    
    # Control and priority (tex specification)
    controllable::Bool            = false
    priority::Int                 = 3
end


"""
    FlexibleLoad

Demand-response / flexible load for VPP and aggregation.
"""
@kwdef struct FlexibleLoad <: AbstractLoad
    index::Int
    name::String                  = ""
    bus::Int
    p_mw::Float64                 = 0.0
    q_mvar::Float64               = 0.0
    flex_up_mw::Float64           = 0.0
    flex_down_mw::Float64         = 0.0
    flex_duration_h::Float64      = 1.0
    response_time_s::Float64      = 60.0
    ramp_rate_mw_min::Float64     = 1.0
    availability_percent::Float64 = 100.0
    control_area::String          = ""
    in_service::Bool              = true
    controllable::Bool            = true
    priority::Int                 = 3
end


"""
    InductionMotor

Asynchronous motor for short-circuit contribution analysis.
Conforms to component_models.tex Motor specification.
"""
@kwdef struct InductionMotor <: AbstractLoad
    # Basic identification
    index::Int
    name::String                  = ""
    bus::Int
    in_service::Bool              = true
    
    # Rated parameters
    vn_kv::Float64                            # Rated voltage (kV)
    sn_mva::Float64                           # Rated capacity (MVA)
    cos_phi::Float64              = 0.85      # Power factor
    efficiency::Float64           = 0.9       # Motor efficiency
    poles::Int                    = 2         # Number of poles
    
    # Voltage limits
    vm_max_pu::Float64            = 1.1
    vm_min_pu::Float64            = 0.9
    
    # Short-circuit parameters
    x_pu::Float64                 = 0.2       # Reactance (p.u.)
    x_r::Float64                  = 10.0      # X/R ratio
    r_pu::Float64                 = 0.02      # Resistance (p.u.)
    tdp::Float64                  = 0.0       # Stator transient time constant (s)
    lrc::Float64                  = 6.0       # Locked rotor current ratio (ILR/Ir)
    
    # Zero-sequence
    x0_pu::Float64                = 0.0
    x0_r0::Float64                = 0.0
    r0_pu::Float64                = 0.0
end
