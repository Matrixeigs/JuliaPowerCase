# ═══════════════════════════════════════════════════════════════════════════════
# Struct → Matrix Conversion
# ═══════════════════════════════════════════════════════════════════════════════

"""
    to_matrix(sys::PowerSystem{K}; T=Float64) -> PowerCaseData{K,T}

Convert a struct-based `PowerSystem` into a matrix-based `PowerCaseData`.
Each component vector is packed into the corresponding `ComponentMatrix`.
"""
function to_matrix(sys::PowerSystem{K}; T::Type{<:Real}=Float64) where K
    jpc = PowerCaseData{K, T}()
    jpc.name     = sys.name
    jpc.base_mva = T(sys.base_mva)
    jpc.base_kv  = T(sys.base_kv)
    jpc.freq_hz  = T(sys.freq_hz)
    jpc.version  = sys.version

    # ── Buses ─────────────────────────────────────────────────────────────
    nb = length(sys.buses)
    if nb > 0
        jpc.bus = ComponentMatrix{BusSchema, T}(nb)
        for (i, b) in enumerate(sys.buses)
            _pack_bus!(jpc.bus, i, b, T)
            # Store name in sidecar if non-empty
            if !isempty(b.name)
                jpc.component_names[(:bus, b.index)] = b.name
            end
        end
    end

    # ── Branches ──────────────────────────────────────────────────────────
    nbr = length(sys.branches)
    if nbr > 0
        jpc.branch = ComponentMatrix{BranchSchema, T}(nbr)
        for (i, br) in enumerate(sys.branches)
            _pack_branch!(jpc.branch, i, br, T)
            if !isempty(br.name)
                jpc.component_names[(:branch, br.index)] = br.name
            end
        end
    end

    # ── Generators ────────────────────────────────────────────────────────
    ng = length(sys.generators)
    if ng > 0
        jpc.gen = ComponentMatrix{GenSchema, T}(ng)
        for (i, g) in enumerate(sys.generators)
            _pack_gen!(jpc.gen, i, g, T)
            if !isempty(g.name)
                jpc.component_names[(:gen, g.index)] = g.name
            end
        end
    end

    # ── Loads ─────────────────────────────────────────────────────────────
    nl = length(sys.loads)
    if nl > 0
        jpc.load = ComponentMatrix{LoadSchema, T}(nl)
        for (i, l) in enumerate(sys.loads)
            _pack_load!(jpc.load, i, l, T)
            if !isempty(l.name)
                jpc.component_names[(:load, l.index)] = l.name
            end
        end
    end

    # ── Storage ───────────────────────────────────────────────────────────
    ns = length(sys.storage)
    if ns > 0
        jpc.storage = ComponentMatrix{StorageSchema, T}(ns)
        for (i, s) in enumerate(sys.storage)
            _pack_storage!(jpc.storage, i, s, T)
            if !isempty(s.name)
                jpc.component_names[(:storage, s.index)] = s.name
            end
        end
    end

    # ── Static Generators (PV, Wind, etc.) ────────────────────────────────
    nsg = length(sys.static_generators)
    if nsg > 0
        jpc.sgen = ComponentMatrix{SgenSchema, T}(nsg)
        for (i, sg) in enumerate(sys.static_generators)
            _pack_sgen!(jpc.sgen, i, sg, T)
            if !isempty(sg.name)
                jpc.component_names[(:sgen, sg.index)] = sg.name
            end
        end
    end

    # ── External Grids ────────────────────────────────────────────────────
    neg = length(sys.external_grids)
    if neg > 0
        jpc.ext_grid = ComponentMatrix{ExtGridSchema, T}(neg)
        for (i, eg) in enumerate(sys.external_grids)
            _pack_ext_grid!(jpc.ext_grid, i, eg, T)
            if !isempty(eg.name)
                jpc.component_names[(:ext_grid, eg.index)] = eg.name
            end
        end
    end

    # ── Switches ──────────────────────────────────────────────────────────
    nsw = length(sys.switches)
    if nsw > 0
        jpc.switch = ComponentMatrix{SwitchSchema, T}(nsw)
        for (i, sw) in enumerate(sys.switches)
            _pack_switch!(jpc.switch, i, sw, T)
            if !isempty(sw.name)
                jpc.component_names[(:switch, sw.index)] = sw.name
            end
        end
    end

    # ── VSC Converters (from vsc_converters or fallback to converters) ─────
    vsc_list = isempty(sys.vsc_converters) ? sys.converters : sys.vsc_converters
    nvsc = length(vsc_list)
    if nvsc > 0
        jpc.converter = ComponentMatrix{ConverterSchema, T}(nvsc)
        for (i, c) in enumerate(vsc_list)
            _pack_vsc!(jpc.converter, i, c, T)
            # Store name in sidecar if non-empty
            if !isempty(c.name)
                jpc.component_names[(:vsc, c.index)] = c.name
            end
        end
    end

    # ── DCDC Converters ───────────────────────────────────────────────────
    ndcdc = length(sys.dcdc_converters)
    if ndcdc > 0
        jpc.dcdc = ComponentMatrix{DCDCSchema, T}(ndcdc)
        for (i, dc) in enumerate(sys.dcdc_converters)
            _pack_dcdc!(jpc.dcdc, i, dc, T)
            if !isempty(dc.name)
                jpc.component_names[(:dcdc, dc.index)] = dc.name
            end
        end
    end

    # ── Energy Routers ────────────────────────────────────────────────────
    ner = length(sys.energy_routers)
    if ner > 0
        jpc.energy_router = ComponentMatrix{ERSchema, T}(ner)
        for (i, er) in enumerate(sys.energy_routers)
            _pack_energy_router!(jpc.energy_router, i, er, T)
            if !isempty(er.name)
                jpc.component_names[(:energy_router, er.index)] = er.name
            end
        end
    end

    # ── Energy Router Ports ───────────────────────────────────────────────
    # Collect all ports from all energy routers, setting core_index from parent
    all_ports = Tuple{EnergyRouterPort, Int}[]  # (port, parent_router_index)
    for er in sys.energy_routers
        for port in er.ports
            push!(all_ports, (port, er.index))
        end
    end
    nports = length(all_ports)
    if nports > 0
        jpc.er_port = ComponentMatrix{ERPortSchema, T}(nports)
        for (i, (port, router_idx)) in enumerate(all_ports)
            _pack_er_port!(jpc.er_port, i, port, router_idx, T)
            if !isempty(port.name)
                jpc.component_names[(:er_port, port.index)] = port.name
            end
        end
    end

    return jpc
end


# ── Pack helpers ──────────────────────────────────────────────────────────────

function _pack_bus!(mat, i, b::Bus, T)
    mat[i, :I]           = T(b.index)
    mat[i, :TYPE]        = T(Int(b.bus_type))
    mat[i, :PD]          = T(b.pd_mw)
    mat[i, :QD]          = T(b.qd_mvar)
    mat[i, :GS]          = T(b.gs_mw)
    mat[i, :BS]          = T(b.bs_mvar)
    mat[i, :AREA]        = T(b.area)
    mat[i, :VM]          = T(b.vm_pu)
    mat[i, :VA]          = T(b.va_deg)
    mat[i, :BASE_KV]     = T(b.base_kv)
    mat[i, :ZONE]        = T(b.zone)
    mat[i, :VMAX]        = T(b.vmax_pu)
    mat[i, :VMIN]        = T(b.vmin_pu)
    # Extended: carbon areas
    mat[i, :CARBON_AREA] = T(b.carbon_area)
    mat[i, :CARBON_ZONE] = T(b.carbon_zone)
    # Extended: resilience parameters
    mat[i, :PER_CONSUMER] = T(b.nc)
    mat[i, :OMEGA]        = T(b.omega)  # Importance weight (重要度)
end

function _pack_branch!(mat, i, br::Branch, T)
    mat[i, :INDEX]   = T(br.index)
    mat[i, :F_BUS]   = T(br.from_bus)
    mat[i, :T_BUS]   = T(br.to_bus)
    mat[i, :BR_R]    = T(br.r_pu)
    mat[i, :BR_X]    = T(br.x_pu)
    mat[i, :BR_B]    = T(br.b_pu)
    mat[i, :RATE_A]  = T(br.rate_a_mva)
    mat[i, :RATE_B]  = T(br.rate_b_mva)
    mat[i, :RATE_C]  = T(br.rate_c_mva)
    mat[i, :TAP]     = T(br.tap)
    mat[i, :SHIFT]   = T(br.shift_deg)
    mat[i, :STATUS]  = T(br.in_service ? 1 : 0)
    mat[i, :ANGMIN]  = T(br.angmin_deg)
    mat[i, :ANGMAX]  = T(br.angmax_deg)
    # Extended: rated parameters
    mat[i, :SN_MVA]  = T(br.s_rated_mva)
    mat[i, :MAX_I]   = T(br.s_max_mva)  # Max current capacity (borrowed column)
    # Extended: reliability
    mat[i, :SW_TIME] = T(br.sw_hours)
    mat[i, :RP_TIME] = T(br.rp_hours)
    # Extended: zero-sequence
    mat[i, :BR_R0]   = T(br.r0_pu)
    mat[i, :BR_X0]   = T(br.x0_pu)
    mat[i, :BR_B0]   = T(br.b0_pu)
end

function _pack_gen!(mat, i, g::Generator, T)
    mat[i, :INDEX]      = T(g.index)
    mat[i, :GEN_BUS]    = T(g.bus)
    mat[i, :PG]         = T(g.pg_mw)
    mat[i, :QG]         = T(g.qg_mvar)
    mat[i, :QMAX]       = T(g.qmax_mvar)
    mat[i, :QMIN]       = T(g.qmin_mvar)
    mat[i, :VG]         = T(g.vg_pu)
    mat[i, :MBASE]      = T(g.mbase_mva)
    mat[i, :GEN_STATUS] = T(g.in_service ? 1 : 0)
    mat[i, :PMAX]       = T(g.pmax_mw)
    mat[i, :PMIN]       = T(g.pmin_mw)
    # Extended: ramp rates
    mat[i, :RAMP_AGC]   = T(g.ramp_agc)
    mat[i, :RAMP_10]    = T(g.ramp_10)
    mat[i, :RAMP_30]    = T(g.ramp_30)
    # Extended: cost model
    mat[i, :MODEL]      = T(Int(g.cost_model))
    mat[i, :STARTUP]    = T(g.cost_startup)
    mat[i, :SHUTDOWN]   = T(g.cost_shutdown)
    # Extended: emissions
    mat[i, :CARBON_EMISSION] = T(g.co2_emission_rate)
    # Extended: short-circuit parameters
    mat[i, :VN_KV]      = T(g.vn_kv)
    mat[i, :XD_SUB]     = T(g.xd_sub_pu)
    mat[i, :X_R]        = T(g.x_r)
    mat[i, :RA]         = T(g.ra_pu)
    mat[i, :COS_PHI]    = T(g.cos_phi)
    mat[i, :XD]         = T(g.xd_pu)
    mat[i, :XQ]         = T(g.xq_pu)
    mat[i, :X0]         = T(g.x0_pu)
    # Sequence network parameters
    mat[i, :R1]         = T(g.r1_pu)
    mat[i, :X1]         = T(g.x1_pu)
    mat[i, :R2]         = T(g.r2_pu)
    mat[i, :X2]         = T(g.x2_pu)
end

function _pack_load!(mat, i, l::Load, T)
    mat[i, :LOAD_I]      = T(l.index)
    mat[i, :LOAD_BUS]    = T(l.bus)
    mat[i, :LOAD_STATUS] = T(l.in_service ? 1 : 0)
    mat[i, :LOAD_PD]     = T(l.p_mw)
    mat[i, :LOAD_QD]     = T(l.q_mvar)
    mat[i, :SCALING]     = T(l.scaling)
    # Extended: ZIP model
    mat[i, :Z_PERCENT]   = T(l.const_z_percent)
    mat[i, :I_PERCENT]   = T(l.const_i_percent)
    mat[i, :P_PERCENT]   = T(l.const_p_percent)
    # Extended: short-circuit / motor params
    mat[i, :SN_MVA]      = T(l.sn_mva)
    mat[i, :VN_KV]       = T(l.vn_kv)
    mat[i, :MOTOR_PERCENT] = T(l.motor_percent)
    mat[i, :LRC]         = T(l.lrc)
    mat[i, :X_R]         = T(l.x_r)
    mat[i, :X_SUB]       = T(l.x_sub_pu)
end

function _pack_storage!(mat, i, s::Storage, T)
    mat[i, :INDEX]         = T(s.index)
    mat[i, :STOR_BUS]      = T(s.bus)
    mat[i, :STOR_STATUS]   = T(s.in_service ? 1 : 0)
    mat[i, :STOR_P]        = T(s.p_mw)
    mat[i, :STOR_EMAX]     = T(s.e_rated_mwh)
    mat[i, :STOR_PMAX]     = T(s.pmax_mw)
    mat[i, :STOR_PMIN]     = T(s.pmin_mw)
    mat[i, :STOR_ETA_CH]   = T(s.eta_charge)
    mat[i, :STOR_ETA_DIS]  = T(s.eta_discharge)
    mat[i, :STOR_SOC_MIN]  = T(s.soc_min)
    mat[i, :STOR_SOC_MAX]  = T(s.soc_max)
    mat[i, :STOR_SOC_INIT] = T(s.soc_init)
    mat[i, :STOR_E_MWH]    = T(s.e_mwh)  # Current stored energy
end

function _pack_sgen!(mat, i, sg::StaticGenerator, T)
    mat[i, :ID]           = T(sg.index)
    mat[i, :BUS]          = T(sg.bus)
    mat[i, :IN_SERVICE]   = T(sg.in_service ? 1 : 0)
    # Type encoding: :pv=1, :wind=2, :chp=3, :fuel_cell=4, :diesel=5
    mat[i, :SGEN_TYPE]    = T(sg.sgen_type == :pv ? 1 : sg.sgen_type == :wind ? 2 : sg.sgen_type == :chp ? 3 : sg.sgen_type == :fuel_cell ? 4 : 5)
    # Rated parameters
    mat[i, :P_RATED_MW]   = T(sg.p_rated_mw)
    mat[i, :Q_RATED_MVAR] = T(sg.q_rated_mvar)
    mat[i, :SN_MVA]       = T(sg.sn_mva)
    # Operating state
    mat[i, :P_MW]         = T(sg.p_mw)
    mat[i, :Q_MVAR]       = T(sg.q_mvar)
    mat[i, :SCALING]      = T(sg.scaling)
    # Power limits
    mat[i, :PMAX]         = T(sg.pmax_mw)
    mat[i, :PMIN]         = T(sg.pmin_mw)
    mat[i, :QMAX]         = T(sg.qmax_mvar)
    mat[i, :QMIN]         = T(sg.qmin_mvar)
    # Control parameters
    mat[i, :CONTROLLABLE] = T(sg.controllable ? 1 : 0)
    mat[i, :V_REF_PU]     = T(sg.v_ref_pu)
    mat[i, :K_P]          = T(sg.k_p)
    mat[i, :K_Q]          = T(sg.k_q)
    mat[i, :F_REF_HZ]     = T(sg.f_ref_hz)
    # Short-circuit parameters
    mat[i, :K_SC]         = T(sg.k)
    mat[i, :RX]           = T(sg.rx)
    # Reliability
    mat[i, :MTBF_H]       = T(sg.mtbf_hours)
    mat[i, :MTTR_H]       = T(sg.mttr_hours)
    mat[i, :T_SCHED_H]    = T(sg.t_scheduled_h)
    # Emissions
    mat[i, :CO2_RATE]     = T(sg.co2_emission_rate)
end

function _pack_ext_grid!(mat, i, eg::ExternalGrid, T)
    mat[i, :INDEX]   = T(eg.index)
    mat[i, :BUS]     = T(eg.bus)
    mat[i, :VN_KV]   = T(eg.vn_kv)
    mat[i, :STATUS]  = T(eg.in_service ? 1 : 0)
    mat[i, :IKQ]     = T(eg.ikq)
    mat[i, :X_R]     = T(eg.x_r)
    mat[i, :R]       = T(eg.r_pu)
    mat[i, :X]       = T(eg.x_pu)
    mat[i, :R0]      = T(eg.r0_pu)
    mat[i, :X0]      = T(eg.x0_pu)
end

function _pack_switch!(mat, i, sw::Switch, T)
    mat[i, :INDEX]        = T(sw.index)
    mat[i, :BUS_FROM]     = T(sw.bus_from)
    mat[i, :BUS_TO]       = T(sw.bus_to)
    mat[i, :ELEMENT_TYPE] = T(Int(sw.element_type == :line ? 1 : sw.element_type == :trafo ? 2 : 3))
    mat[i, :ELEMENT_ID]   = T(sw.element_id)
    mat[i, :CLOSED]       = T(sw.closed ? 1 : 0)
    mat[i, :SWITCH_TYPE]  = T(Int(sw.switch_type == :cb ? 1 : sw.switch_type == :ls ? 2 : sw.switch_type == :ds ? 3 : sw.switch_type == :fuse ? 4 : 5))
    mat[i, :Z_OHM]        = T(sw.z_ohm)
    mat[i, :IN_SERVICE]   = T(sw.in_service ? 1 : 0)
end

function _pack_vsc!(mat, i, c::VSCConverter, T)
    # Basic identification
    mat[i, :INDEX]        = T(c.index)
    mat[i, :ACBUS]        = T(c.bus_ac)
    mat[i, :DCBUS]        = T(c.bus_dc)
    mat[i, :INSERVICE]    = T(c.in_service ? 1 : 0)
    # VSC type encoding: "Two-Level"=1, "Three-Level"=2, "MMC"=3
    mat[i, :VSC_TYPE]     = T(c.vsc_type == "Two-Level" ? 1 : c.vsc_type == "Three-Level" ? 2 : 3)
    # Rated parameters
    mat[i, :P_RATED_MW]   = T(c.p_rated_mw)
    mat[i, :VN_AC_KV]     = T(c.vn_ac_kv)
    mat[i, :VN_DC_KV]     = T(c.vn_dc_kv)
    # Operating state
    mat[i, :P_AC]         = T(c.p_mw)
    mat[i, :Q_AC]         = T(c.q_mvar)
    mat[i, :VM_AC_PU]     = T(c.vm_ac_pu)
    mat[i, :VM_DC_PU]     = T(c.vm_dc_pu)
    # Power limits
    mat[i, :PMAX]         = T(c.pmax_mw)
    mat[i, :PMIN]         = T(c.pmin_mw)
    mat[i, :QMAX]         = T(c.qmax_mvar)
    mat[i, :QMIN]         = T(c.qmin_mvar)
    # Efficiency and losses
    mat[i, :EFF]          = T(c.eta)
    mat[i, :LOSS_PERCENT] = T(c.loss_percent)
    mat[i, :LOSS_MW]      = T(c.loss_mw)
    # Control parameters
    mat[i, :CONTROLLABLE] = T(c.controllable ? 1 : 0)
    # Control mode encoding: :pq=1, :pv=2, :vdc_q=3, :droop=4
    mat[i, :MODE]         = T(Int(c.control_mode == :pq ? 1 : c.control_mode == :pv ? 2 : c.control_mode == :vdc_q ? 3 : 4))
    mat[i, :P_SET]        = T(c.p_set_mw)
    mat[i, :Q_SET]        = T(c.q_set_mvar)
    mat[i, :V_AC_SET]     = T(c.v_ac_set_pu)
    mat[i, :V_DC_SET]     = T(c.v_dc_set_pu)
    # Droop control parameters
    mat[i, :K_VDC]        = T(c.k_vdc)
    mat[i, :K_P]          = T(c.k_p)
    mat[i, :K_Q]          = T(c.k_q)
    mat[i, :V_REF_PU]     = T(c.v_ref_pu)
    mat[i, :F_REF_HZ]     = T(c.f_ref_hz)
    # Reliability parameters
    mat[i, :MTBF_H]       = T(c.mtbf_hours)
    mat[i, :MTTR_H]       = T(c.mttr_hours)
    mat[i, :T_SCHED_H]    = T(c.t_scheduled_h)
end

function _pack_dcdc!(mat, i, dc::DCDCConverter, T)
    # Basic identification
    mat[i, :INDEX]        = T(dc.index)
    mat[i, :BUS_IN]       = T(dc.bus_in)
    mat[i, :BUS_OUT]      = T(dc.bus_out)
    mat[i, :INSERVICE]    = T(dc.in_service ? 1 : 0)
    mat[i, :CONTROLLABLE] = T(dc.controllable ? 1 : 0)
    # Operating state
    mat[i, :V_IN_PU]      = T(dc.v_in_pu)
    mat[i, :V_OUT_PU]     = T(dc.v_out_pu)
    mat[i, :P_IN_MW]      = T(dc.p_in_mw)
    mat[i, :P_OUT_MW]     = T(dc.p_out_mw)
    mat[i, :P_REF_MW]     = T(dc.p_ref_mw)
    mat[i, :V_REF_PU]     = T(dc.v_ref_pu)
    # Rated parameters
    mat[i, :SN_MVA]       = T(dc.sn_mva)
    mat[i, :VN_IN_KV]     = T(dc.vn_in_kv)
    mat[i, :VN_OUT_KV]    = T(dc.vn_out_kv)
    # Efficiency and losses
    mat[i, :EFF]          = T(dc.eta)
    mat[i, :R_EQ_PU]      = T(dc.r_eq_pu)
    mat[i, :F_SWITCH_KHZ] = T(dc.f_switching_khz)
    # Power limits
    mat[i, :PMAX]         = T(dc.pmax_mw)
    mat[i, :PMIN]         = T(dc.pmin_mw)
    # Control mode encoding: :power=1, :voltage=2, :droop=3
    mat[i, :MODE]         = T(Int(dc.control_mode == :power ? 1 : dc.control_mode == :voltage ? 2 : 3))
    mat[i, :K_DROOP]      = T(dc.k_droop)
    # Reliability parameters
    mat[i, :MTBF_H]       = T(dc.mtbf_hours)
    mat[i, :MTTR_H]       = T(dc.mttr_hours)
    mat[i, :T_SCHED_H]    = T(dc.t_scheduled_h)
end

function _pack_energy_router!(mat, i, er::EnergyRouter, T)
    # Basic identification
    mat[i, :ID]           = T(er.index)
    mat[i, :INSERVICE]    = T(er.in_service ? 1 : 0)
    # Router type encoding: "3-port"=1, "4-port"=2, "Multi-port"=3
    mat[i, :ER_TYPE]      = T(er.router_type == "3-port" ? 1 : er.router_type == "4-port" ? 2 : 3)
    mat[i, :NUM_PORTS]    = T(er.num_ports)
    # Rated parameters
    mat[i, :P_RATED_MW]   = T(er.p_rated_mw)
    mat[i, :VN_AC_KV]     = T(er.vn_ac_kv)
    mat[i, :VN_DC_KV]     = T(er.vn_dc_kv)
    # Loss parameters
    mat[i, :LOSS_PERCENT] = T(er.loss_percent)
    # Control mode encoding: "PowerDispatch"=1, "VoltageControl"=2, "Droop"=3
    mat[i, :MODE]         = T(er.control_mode == "PowerDispatch" ? 1 : er.control_mode == "VoltageControl" ? 2 : 3)
    # Dispatch strategy encoding: "Proportional"=1, "Optimal"=2, "Manual"=3
    mat[i, :DISPATCH_STRATEGY] = T(er.power_dispatch_strategy == "Proportional" ? 1 : er.power_dispatch_strategy == "Optimal" ? 2 : 3)
    # Power limits
    mat[i, :PMAX]         = T(er.pmax_mw)
    mat[i, :PMIN]         = T(er.pmin_mw)
    mat[i, :QMAX]         = T(er.qmax_mvar)
    mat[i, :QMIN]         = T(er.qmin_mvar)
    # Voltage limits
    mat[i, :VMAX_PU]      = T(er.vmax_pu)
    mat[i, :VMIN_PU]      = T(er.vmin_pu)
    # Reliability parameters
    mat[i, :MTBF_H]       = T(er.mtbf_hours)
    mat[i, :MTTR_H]       = T(er.mttr_hours)
    mat[i, :T_SCHED_H]    = T(er.t_scheduled_h)
    # Economic parameters
    mat[i, :INVEST_COST]  = T(er.investment_cost)
    mat[i, :OP_COST_MWH]  = T(er.operation_cost_per_mwh)
    mat[i, :MAINT_COST_YR] = T(er.maintenance_cost_per_year)
end

function _pack_er_port!(mat, i, port::EnergyRouterPort, router_idx::Int, T)
    mat[i, :ID]        = T(port.index)
    mat[i, :ROUTER_ID] = T(router_idx)  # Use parent router index, not port.core_index
    mat[i, :BUS]       = T(port.bus)
    # Port type encoding: :ac=1, :dc=2
    mat[i, :PORT_TYPE] = T(port.port_type == :ac ? 1 : 2)
    mat[i, :VN_KV]     = T(port.voltage_level_kv)
    # Operating state
    mat[i, :P_AC_MW]   = T(port.p_ac_mw)
    mat[i, :Q_AC_MVAR] = T(port.q_ac_mvar)
    mat[i, :V_AC_PU]   = T(port.v_ac_pu)
    mat[i, :P_DC_MW]   = T(port.p_dc_mw)
    mat[i, :V_DC_PU]   = T(port.v_dc_pu)
    mat[i, :PHI_DEG]   = T(port.phi_deg)
    # Power limits
    mat[i, :PMAX]      = T(port.pmax_mw)
    mat[i, :PMIN]      = T(port.pmin_mw)
    mat[i, :QMAX]      = T(port.qmax_mvar)
    mat[i, :QMIN]      = T(port.qmin_mvar)
    # Control mode encoding: :p=1, :q=2, :v=3, :pq=4, :pv=5, :vf=6
    mat[i, :MODE]      = T(port.control_mode == :p ? 1 : port.control_mode == :q ? 2 : port.control_mode == :v ? 3 : port.control_mode == :pq ? 4 : port.control_mode == :pv ? 5 : 6)
    mat[i, :P_SET]     = T(port.p_set_mw)
    mat[i, :Q_SET]     = T(port.q_set_mvar)
    mat[i, :V_SET]     = T(port.v_set_pu)
    mat[i, :INSERVICE] = T(port.in_service ? 1 : 0)
    # Side encoding: :primary=1, :secondary=2
    mat[i, :SIDE]      = T(port.side == :primary ? 1 : 2)
end
