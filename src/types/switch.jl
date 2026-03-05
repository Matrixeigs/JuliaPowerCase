# ═══════════════════════════════════════════════════════════════════════════════
# Switch — circuit breaker, load switch, disconnector, fuse, HVCB
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Switch

Generic switch: circuit breaker, load switch, disconnector, fuse, HVCB.
Covers all switch/breaker ratings in a single unified type.
Conforms to component_models.tex Switch and HVCB specifications.
"""
@kwdef struct Switch <: AbstractSwitch
    # Basic identification
    index::Int
    name::String                  = ""
    bus_from::Int
    bus_to::Int
    in_service::Bool              = true
    
    # Connection reference
    element_type::Symbol          = :line     # :line, :trafo, :bus
    element_id::Int               = 0
    
    # Switch type and state
    switch_type::Symbol           = :cb       # :cb, :ls, :ds, :fuse, :hvcb
    closed::Bool                  = true      # true = closed, false = open (status in tex)
    
    # Electrical parameters
    r_contact_ohm::Float64        = 0.0       # Contact resistance (Ohm)
    z_ohm::Float64                = 0.0       # Impedance (Ohm) for simplified model
    i_rated_ka::Float64           = 10.0      # Rated current (kA)
    i_breaking_ka::Float64        = 25.0      # Breaking current capacity (kA, for HVCB)
    
    # Reliability parameters
    mtbf_hours::Float64           = 87600.0   # Mean time between failures (h) ~10 years
    mttr_hours::Float64           = 4.0       # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    
    # Operation parameters
    p_sw_fail::Float64            = 0.001     # Switch failure probability per operation
    t_operation_s::Float64        = 0.05      # Operation time (s)
    t_tp_s::Float64               = 0.0       # Transfer/trip time (s)
    
    # Automation
    is_remote::Bool               = false     # Remote controllable
    is_automated::Bool            = false     # Has automation controller
end
