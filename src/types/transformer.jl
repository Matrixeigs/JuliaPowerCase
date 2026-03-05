# ═══════════════════════════════════════════════════════════════════════════════
# Transformers — 2-Winding and 3-Winding
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Transformer2W

Two-winding transformer with tap changer and zero-sequence parameters.
Conforms to component_models.tex Transformer2W specification.
"""
@kwdef struct Transformer2W <: AbstractBranch
    # Basic identification
    index::Int
    name::String                  = ""
    std_type::String              = ""        # Standard type reference
    hv_bus::Int
    lv_bus::Int
    in_service::Bool              = true
    
    # Parallel circuits
    n_parallel::Int               = 1         # Number of parallel transformers
    
    # Rated parameters
    sn_mva::Float64                           # Rated apparent power (MVA)
    vn_hv_kv::Float64                         # HV rated voltage (kV)
    vn_lv_kv::Float64                         # LV rated voltage (kV)
    
    # Short-circuit parameters
    vk_percent::Float64           = 10.0      # Short-circuit voltage (%)
    vkr_percent::Float64          = 0.5       # Short-circuit voltage resistive (%)
    pk_kw::Float64                = 0.0       # Short-circuit loss (kW) - alias for computing from vkr
    
    # No-load parameters
    pfe_kw::Float64               = 0.0       # Iron loss (kW)
    i0_percent::Float64           = 0.0       # No-load current (%)
    
    # Tap changer
    tap_side::Symbol              = :hv       # :hv or :lv
    tap_pos::Int                  = 0         # Current tap position
    tap_min::Int                  = -10       # Minimum tap position
    tap_max::Int                  = 10        # Maximum tap position
    tap_step_percent::Float64     = 1.25      # Tap step size (%)
    tap_neutral::Int              = 0         # Neutral tap position
    
    # Phase shift
    shift_deg::Float64            = 0.0       # Phase shift angle (degrees)
    vector_group::String          = "Dyn11"   # Vector group designation
    
    # Zero-sequence parameters
    z0_percent::Float64           = 10.0      # Zero-sequence impedance (%)
    x0_r0::Float64                = 10.0      # X0/R0 ratio
    
    # Reliability parameters
    mtbf_hours::Float64           = 175200.0  # Mean time between failures (h) ~20 years
    mttr_hours::Float64           = 168.0     # Mean time to repair (h) ~1 week
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
end

"""
    Transformer3W

Three-winding transformer.
Conforms to component_models.tex Transformer3W specification.
"""
@kwdef struct Transformer3W <: AbstractBranch
    # Basic identification
    index::Int
    name::String                  = ""
    std_type::String              = ""        # Standard type reference
    hv_bus::Int
    mv_bus::Int
    lv_bus::Int
    in_service::Bool              = true
    
    # Rated parameters per winding
    sn_hv_mva::Float64                        # HV rated power (MVA)
    sn_mv_mva::Float64                        # MV rated power (MVA)
    sn_lv_mva::Float64                        # LV rated power (MVA)
    vn_hv_kv::Float64                         # HV rated voltage (kV)
    vn_mv_kv::Float64                         # MV rated voltage (kV)
    vn_lv_kv::Float64                         # LV rated voltage (kV)
    
    # Short-circuit parameters (winding pairs)
    vk_hv_mv_percent::Float64     = 10.0      # HV-MV short-circuit voltage (%)
    vk_hv_lv_percent::Float64     = 10.0      # HV-LV short-circuit voltage (%)
    vk_mv_lv_percent::Float64     = 10.0      # MV-LV short-circuit voltage (%)
    vkr_hv_mv_percent::Float64    = 0.5       # HV-MV short-circuit resistance (%)
    vkr_hv_lv_percent::Float64    = 0.5       # HV-LV short-circuit resistance (%)
    vkr_mv_lv_percent::Float64    = 0.5       # MV-LV short-circuit resistance (%)
    
    # Legacy field names for compatibility
    vk_hv_percent::Float64        = 10.0
    vk_mv_percent::Float64        = 10.0
    vk_lv_percent::Float64        = 10.0
    vkr_hv_percent::Float64       = 0.5
    vkr_mv_percent::Float64       = 0.5
    vkr_lv_percent::Float64       = 0.5
    
    # No-load parameters
    pfe_kw::Float64               = 0.0       # Iron loss (kW)
    i0_percent::Float64           = 0.0       # No-load current (%)
    
    # Tap changer
    tap_side::Symbol              = :hv       # :hv, :mv, or :lv
    tap_pos::Int                  = 0
    tap_step_percent::Float64     = 1.25
    
    # Phase shifts
    shift_mv_deg::Float64         = 0.0       # MV phase shift (degrees)
    shift_lv_deg::Float64         = 0.0       # LV phase shift (degrees)
    
    # Reliability parameters
    mtbf_hours::Float64           = 175200.0  # Mean time between failures (h)
    mttr_hours::Float64           = 168.0     # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
end
