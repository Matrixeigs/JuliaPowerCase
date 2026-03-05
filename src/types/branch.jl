# ═══════════════════════════════════════════════════════════════════════════════
# Branch — AC/DC unified via phantom type parameter
# ═══════════════════════════════════════════════════════════════════════════════

"""
    Branch{K<:SystemKind}

Transmission or distribution line/cable. Parametric on `AC`/`DC`.
Conforms to component_models.tex Line/Cable/LineDC specification.

# Fields
- `index::Int`
- `name::String`
- `from_bus::Int` — sending-end bus index
- `to_bus::Int` — receiving-end bus index
- `r_pu::Float64` — series resistance (p.u.)
- `x_pu::Float64` — series reactance (p.u.)
- `b_pu::Float64` — total charging susceptance (p.u.)
- `rate_a_mva::Float64` — long-term MVA rating
- `rate_b_mva::Float64` — short-term MVA rating
- `rate_c_mva::Float64` — emergency MVA rating
- `tap::Float64` — off-nominal tap ratio (1.0 for line)
- `shift_deg::Float64` — phase shift (degrees)
- `angmin_deg::Float64` — minimum angle difference
- `angmax_deg::Float64` — maximum angle difference
- `length_km::Float64` — physical length (km)
- `in_service::Bool`
- `branch_type::Symbol` — `:line`, `:cable`, `:trafo`
"""
@kwdef struct Branch{K<:SystemKind} <: AbstractBranch
    # Basic identification
    index::Int
    name::String                  = ""
    from_bus::Int
    to_bus::Int
    in_service::Bool              = true
    branch_type::Symbol           = :line     # :line, :cable, :trafo
    
    # Physical parameters
    length_km::Float64            = 1.0       # Physical length (km)
    n_parallel::Int               = 1         # Number of parallel circuits
    
    # Rated parameters
    v_rated_kv::Float64           = 0.0       # Rated voltage (kV)
    s_rated_mva::Float64          = 0.0       # Rated power (MVA)
    s_max_mva::Float64            = 9999.0    # Maximum power (MVA)
    
    # Per-unit impedance (on system base)
    r_pu::Float64                 = 0.0       # Series resistance (p.u.)
    x_pu::Float64                 = 0.01      # Series reactance (p.u.)
    b_pu::Float64                 = 0.0       # Total charging susceptance (p.u.)
    
    # Per-km parameters (physical, for unit conversion)
    r_ohm_km::Float64             = 0.0       # Resistance per km (Ω/km)
    x_ohm_km::Float64             = 0.0       # Reactance per km (Ω/km)
    c_nf_km::Float64              = 0.0       # Capacitance per km (nF/km)
    b_us_km::Float64              = 0.0       # Susceptance per km (µS/km)
    
    # Zero-sequence parameters (for short-circuit)
    r0_pu::Float64                = 0.0       # Zero-sequence resistance (p.u.)
    x0_pu::Float64                = 0.0       # Zero-sequence reactance (p.u.)
    b0_pu::Float64                = 0.0       # Zero-sequence susceptance (p.u.)
    c0_nf_km::Float64             = 0.0       # Zero-sequence capacitance (nF/km, for cables)
    
    # Power flow ratings
    rate_a_mva::Float64           = 9999.0    # Long-term rating (MVA)
    rate_b_mva::Float64           = 9999.0    # Short-term rating (MVA)
    rate_c_mva::Float64           = 9999.0    # Emergency rating (MVA)
    
    # Transformer/phase-shifter parameters (for branch_type = :trafo)
    tap::Float64                  = 1.0       # Off-nominal tap ratio
    shift_deg::Float64            = 0.0       # Phase shift (degrees)
    angmin_deg::Float64           = -360.0    # Minimum angle difference
    angmax_deg::Float64           = 360.0     # Maximum angle difference
    
    # Reliability parameters
    mtbf_hours::Float64           = 8760.0    # Mean time between failures (h)
    mttr_hours::Float64           = 4.0       # Mean time to repair (h)
    t_scheduled_h::Float64        = 0.0       # Scheduled maintenance (h/year)
    sw_hours::Float64             = 0.5       # Switching time (h)
    rp_hours::Float64             = 0.0       # Restoration priority time (h)
end

const ACBranch = Branch{AC}
const DCBranch = Branch{DC}
