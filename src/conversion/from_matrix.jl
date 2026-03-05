# ═══════════════════════════════════════════════════════════════════════════════
# Matrix → Struct Conversion
# ═══════════════════════════════════════════════════════════════════════════════

"""
    from_matrix(jpc::PowerCaseData{K,T}) -> PowerSystem{K}

Convert a matrix-based `PowerCaseData` into a struct-based `PowerSystem`.
Each row of a `ComponentMatrix` is unpacked into the corresponding struct.
"""
function from_matrix(jpc::PowerCaseData{K, T}) where {K, T}
    sys = PowerSystem{K}()
    sys.name     = jpc.name
    sys.base_mva = Float64(jpc.base_mva)
    sys.base_kv  = Float64(jpc.base_kv)
    sys.freq_hz  = Float64(jpc.freq_hz)
    sys.version  = jpc.version

    # ── Buses ─────────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.bus)
        push!(sys.buses, _unpack_bus(jpc.bus, i, K, jpc.component_names))
    end

    # ── Branches ──────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.branch)
        push!(sys.branches, _unpack_branch(jpc.branch, i, K, jpc.component_names))
    end

    # ── Generators ────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.gen)
        push!(sys.generators, _unpack_gen(jpc.gen, i, jpc.component_names))
    end

    # ── Loads ─────────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.load)
        push!(sys.loads, _unpack_load(jpc.load, i, K, jpc.component_names))
    end

    # ── Storage ───────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.storage)
        push!(sys.storage, _unpack_storage(jpc.storage, i, K, jpc.component_names))
    end

    # ── Static Generators ─────────────────────────────────────────────────
    for i in 1:nrows(jpc.sgen)
        push!(sys.static_generators, _unpack_sgen(jpc.sgen, i, K, jpc.component_names))
    end

    # ── External Grids ────────────────────────────────────────────────────
    for i in 1:nrows(jpc.ext_grid)
        push!(sys.external_grids, _unpack_ext_grid(jpc.ext_grid, i, jpc.component_names))
    end

    # ── Switches ──────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.switch)
        push!(sys.switches, _unpack_switch(jpc.switch, i, jpc.component_names))
    end

    # ── Converters ────────────────────────────────────────────────────────
    for i in 1:nrows(jpc.converter)
        c = _unpack_vsc(jpc.converter, i, jpc.component_names)
        push!(sys.vsc_converters, c)
        push!(sys.converters, c)  # Also populate legacy field
    end

    # ── DCDC Converters ───────────────────────────────────────────────────
    for i in 1:nrows(jpc.dcdc)
        dc = _unpack_dcdc(jpc.dcdc, i, jpc.component_names)
        push!(sys.dcdc_converters, dc)
    end

    # ── Energy Routers ────────────────────────────────────────────────────
    for i in 1:nrows(jpc.energy_router)
        er = _unpack_energy_router(jpc.energy_router, i, jpc.component_names)
        push!(sys.energy_routers, er)
    end

    # ── Energy Router Ports ───────────────────────────────────────────────
    # Unpack ports and assign them to their parent energy routers
    # Build a lookup table: router_id -> index in sys.energy_routers
    router_id_to_idx = Dict{Int, Int}()
    for (idx, er) in enumerate(sys.energy_routers)
        router_id_to_idx[er.index] = idx
    end
    # Unpack each port and assign to the correct router
    for i in 1:nrows(jpc.er_port)
        port = _unpack_er_port(jpc.er_port, i, jpc.component_names)
        router_id = port.core_index
        if haskey(router_id_to_idx, router_id)
            push!(sys.energy_routers[router_id_to_idx[router_id]].ports, port)
        end
    end

    # ── Synchronize num_ports with actual port count ──────────────────────
    for (idx, er) in enumerate(sys.energy_routers)
        # Create new EnergyRouter with corrected num_ports if mismatch
        actual_count = length(er.ports)
        if er.num_ports != actual_count
            sys.energy_routers[idx] = _replace_num_ports(er, actual_count)
        end
    end

    return sys
end

"""Helper to create a new EnergyRouter with updated num_ports."""
function _replace_num_ports(er::EnergyRouter, new_count::Int)
    EnergyRouter(
        index = er.index,
        name = er.name,
        in_service = er.in_service,
        router_type = er.router_type,
        num_ports = new_count,
        ports = er.ports,
        p_rated_mw = er.p_rated_mw,
        vn_ac_kv = er.vn_ac_kv,
        vn_dc_kv = er.vn_dc_kv,
        loss_percent = er.loss_percent,
        control_mode = er.control_mode,
        power_dispatch_strategy = er.power_dispatch_strategy,
        pmax_mw = er.pmax_mw,
        pmin_mw = er.pmin_mw,
        qmax_mvar = er.qmax_mvar,
        qmin_mvar = er.qmin_mvar,
        vmax_pu = er.vmax_pu,
        vmin_pu = er.vmin_pu,
        mtbf_hours = er.mtbf_hours,
        mttr_hours = er.mttr_hours,
        t_scheduled_h = er.t_scheduled_h,
        investment_cost = er.investment_cost,
        operation_cost_per_mwh = er.operation_cost_per_mwh,
        maintenance_cost_per_year = er.maintenance_cost_per_year,
    )
end


# ── Unpack helpers ────────────────────────────────────────────────────────────

function _unpack_bus(mat, i, ::Type{K}, component_names::Dict{Tuple{Symbol, Int}, String}) where K
    idx = Int(mat[i, :I])
    name = get(component_names, (:bus, idx), "")
    Bus{K}(
        index       = idx,
        name        = name,
        bus_type    = BusType(Int(mat[i, :TYPE])),
        pd_mw       = Float64(mat[i, :PD]),
        qd_mvar     = Float64(mat[i, :QD]),
        gs_mw       = Float64(mat[i, :GS]),
        bs_mvar     = Float64(mat[i, :BS]),
        area        = Int(mat[i, :AREA]),
        vm_pu       = Float64(mat[i, :VM]),
        va_deg      = Float64(mat[i, :VA]),
        base_kv     = Float64(mat[i, :BASE_KV]),
        zone        = Int(mat[i, :ZONE]),
        vmax_pu     = Float64(mat[i, :VMAX]),
        vmin_pu     = Float64(mat[i, :VMIN]),
        # Extended: carbon areas
        carbon_area = Int(mat[i, :CARBON_AREA]),
        carbon_zone = Int(mat[i, :CARBON_ZONE]),
        # Extended: resilience
        nc          = Int(mat[i, :PER_CONSUMER]),
        omega       = Float64(mat[i, :OMEGA]),
    )
end

function _unpack_branch(mat, i, ::Type{K}, component_names::Dict{Tuple{Symbol, Int}, String}) where K
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:branch, idx), "")
    Branch{K}(
        index       = idx,
        name        = name,
        from_bus    = Int(mat[i, :F_BUS]),
        to_bus      = Int(mat[i, :T_BUS]),
        r_pu        = Float64(mat[i, :BR_R]),
        x_pu        = Float64(mat[i, :BR_X]),
        b_pu        = Float64(mat[i, :BR_B]),
        rate_a_mva  = Float64(mat[i, :RATE_A]),
        rate_b_mva  = Float64(mat[i, :RATE_B]),
        rate_c_mva  = Float64(mat[i, :RATE_C]),
        tap         = Float64(mat[i, :TAP]),
        shift_deg   = Float64(mat[i, :SHIFT]),
        in_service  = mat[i, :STATUS] != 0,
        angmin_deg  = Float64(mat[i, :ANGMIN]),
        angmax_deg  = Float64(mat[i, :ANGMAX]),
        # Extended: rated parameters
        s_rated_mva = Float64(mat[i, :SN_MVA]),
        s_max_mva   = Float64(mat[i, :MAX_I]),
        # Extended: reliability
        sw_hours    = Float64(mat[i, :SW_TIME]),
        rp_hours    = Float64(mat[i, :RP_TIME]),
        # Extended: zero-sequence
        r0_pu       = Float64(mat[i, :BR_R0]),
        x0_pu       = Float64(mat[i, :BR_X0]),
        b0_pu       = Float64(mat[i, :BR_B0]),
    )
end

function _unpack_gen(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:gen, idx), "")
    Generator(
        index         = idx,
        name          = name,
        bus           = Int(mat[i, :GEN_BUS]),
        pg_mw         = Float64(mat[i, :PG]),
        qg_mvar       = Float64(mat[i, :QG]),
        qmax_mvar     = Float64(mat[i, :QMAX]),
        qmin_mvar     = Float64(mat[i, :QMIN]),
        vg_pu         = Float64(mat[i, :VG]),
        mbase_mva     = Float64(mat[i, :MBASE]),
        in_service    = mat[i, :GEN_STATUS] != 0,
        pmax_mw       = Float64(mat[i, :PMAX]),
        pmin_mw       = Float64(mat[i, :PMIN]),
        # Extended: ramp rates
        ramp_agc      = Float64(mat[i, :RAMP_AGC]),
        ramp_10       = Float64(mat[i, :RAMP_10]),
        ramp_30       = Float64(mat[i, :RAMP_30]),
        # Extended: cost model
        cost_model    = GenModel(Int(mat[i, :MODEL])),
        cost_startup  = Float64(mat[i, :STARTUP]),
        cost_shutdown = Float64(mat[i, :SHUTDOWN]),
        # Extended: emissions
        co2_emission_rate = Float64(mat[i, :CARBON_EMISSION]),
        # Extended: short-circuit parameters
        vn_kv         = Float64(mat[i, :VN_KV]),
        xd_sub_pu     = Float64(mat[i, :XD_SUB]),
        x_r           = Float64(mat[i, :X_R]),
        ra_pu         = Float64(mat[i, :RA]),
        cos_phi       = Float64(mat[i, :COS_PHI]),
        xd_pu         = Float64(mat[i, :XD]),
        xq_pu         = Float64(mat[i, :XQ]),
        x0_pu         = Float64(mat[i, :X0]),
        # Sequence network parameters
        r1_pu         = Float64(mat[i, :R1]),
        x1_pu         = Float64(mat[i, :X1]),
        r2_pu         = Float64(mat[i, :R2]),
        x2_pu         = Float64(mat[i, :X2]),
    )
end

function _unpack_load(mat, i, ::Type{K}, component_names::Dict{Tuple{Symbol, Int}, String}) where K
    idx = Int(mat[i, :LOAD_I])
    name = get(component_names, (:load, idx), "")
    Load{K}(
        index           = idx,
        name            = name,
        bus             = Int(mat[i, :LOAD_BUS]),
        p_mw            = Float64(mat[i, :LOAD_PD]),
        q_mvar          = Float64(mat[i, :LOAD_QD]),
        in_service      = mat[i, :LOAD_STATUS] != 0,
        scaling         = Float64(mat[i, :SCALING]),
        # Extended: ZIP model
        const_z_percent = Float64(mat[i, :Z_PERCENT]),
        const_i_percent = Float64(mat[i, :I_PERCENT]),
        const_p_percent = Float64(mat[i, :P_PERCENT]),
        # Extended: short-circuit / motor params
        sn_mva          = Float64(mat[i, :SN_MVA]),
        vn_kv           = Float64(mat[i, :VN_KV]),
        motor_percent   = Float64(mat[i, :MOTOR_PERCENT]),
        lrc             = Float64(mat[i, :LRC]),
        x_r             = Float64(mat[i, :X_R]),
        x_sub_pu        = Float64(mat[i, :X_SUB]),
    )
end

function _unpack_storage(mat, i, ::Type{K}, component_names::Dict{Tuple{Symbol, Int}, String}) where K
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:storage, idx), "")
    Storage{K}(
        index         = idx,
        name          = name,
        bus           = Int(mat[i, :STOR_BUS]),
        in_service    = mat[i, :STOR_STATUS] != 0,
        p_mw          = Float64(mat[i, :STOR_P]),
        e_rated_mwh   = Float64(mat[i, :STOR_EMAX]),
        pmax_mw       = Float64(mat[i, :STOR_PMAX]),
        pmin_mw       = Float64(mat[i, :STOR_PMIN]),
        eta_charge    = Float64(mat[i, :STOR_ETA_CH]),
        eta_discharge = Float64(mat[i, :STOR_ETA_DIS]),
        soc_min       = Float64(mat[i, :STOR_SOC_MIN]),
        soc_max       = Float64(mat[i, :STOR_SOC_MAX]),
        soc_init      = Float64(mat[i, :STOR_SOC_INIT]),
        e_mwh         = Float64(mat[i, :STOR_E_MWH]),
    )
end

function _unpack_sgen(mat, i, ::Type{K}, component_names::Dict{Tuple{Symbol, Int}, String}) where K
    sgen_type_int = Int(mat[i, :SGEN_TYPE])
    sgen_type_sym = sgen_type_int == 1 ? :pv : sgen_type_int == 2 ? :wind : sgen_type_int == 3 ? :chp : sgen_type_int == 4 ? :fuel_cell : :diesel
    idx = Int(mat[i, :ID])
    name = get(component_names, (:sgen, idx), "")
    StaticGenerator{K}(
        index           = idx,
        name            = name,
        bus             = Int(mat[i, :BUS]),
        in_service      = mat[i, :IN_SERVICE] != 0,
        sgen_type       = sgen_type_sym,
        # Rated parameters
        p_rated_mw      = Float64(mat[i, :P_RATED_MW]),
        q_rated_mvar    = Float64(mat[i, :Q_RATED_MVAR]),
        sn_mva          = Float64(mat[i, :SN_MVA]),
        # Operating state
        p_mw            = Float64(mat[i, :P_MW]),
        q_mvar          = Float64(mat[i, :Q_MVAR]),
        scaling         = Float64(mat[i, :SCALING]),
        # Power limits
        pmax_mw         = Float64(mat[i, :PMAX]),
        pmin_mw         = Float64(mat[i, :PMIN]),
        qmax_mvar       = Float64(mat[i, :QMAX]),
        qmin_mvar       = Float64(mat[i, :QMIN]),
        # Control parameters
        controllable    = mat[i, :CONTROLLABLE] != 0,
        v_ref_pu        = Float64(mat[i, :V_REF_PU]),
        k_p             = Float64(mat[i, :K_P]),
        k_q             = Float64(mat[i, :K_Q]),
        f_ref_hz        = Float64(mat[i, :F_REF_HZ]),
        # Short-circuit parameters
        k               = Float64(mat[i, :K_SC]),
        rx              = Float64(mat[i, :RX]),
        # Reliability
        mtbf_hours      = Float64(mat[i, :MTBF_H]),
        mttr_hours      = Float64(mat[i, :MTTR_H]),
        t_scheduled_h   = Float64(mat[i, :T_SCHED_H]),
        # Emissions
        co2_emission_rate = Float64(mat[i, :CO2_RATE]),
    )
end

function _unpack_ext_grid(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:ext_grid, idx), "")
    ExternalGrid(
        index      = idx,
        name       = name,
        bus        = Int(mat[i, :BUS]),
        vn_kv      = Float64(mat[i, :VN_KV]),
        in_service = mat[i, :STATUS] != 0,
        ikq        = Float64(mat[i, :IKQ]),
        x_r        = Float64(mat[i, :X_R]),
        r_pu       = Float64(mat[i, :R]),
        x_pu       = Float64(mat[i, :X]),
        r0_pu      = Float64(mat[i, :R0]),
        x0_pu      = Float64(mat[i, :X0]),
    )
end

function _unpack_switch(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    element_type_int = Int(mat[i, :ELEMENT_TYPE])
    element_type_sym = element_type_int == 1 ? :line : element_type_int == 2 ? :trafo : :bus
    switch_type_int = Int(mat[i, :SWITCH_TYPE])
    switch_type_sym = switch_type_int == 1 ? :cb : switch_type_int == 2 ? :ls : switch_type_int == 3 ? :ds : switch_type_int == 4 ? :fuse : :hvcb
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:switch, idx), "")
    Switch(
        index        = idx,
        name         = name,
        bus_from     = Int(mat[i, :BUS_FROM]),
        bus_to       = Int(mat[i, :BUS_TO]),
        element_type = element_type_sym,
        element_id   = Int(mat[i, :ELEMENT_ID]),
        closed       = mat[i, :CLOSED] != 0,
        switch_type  = switch_type_sym,
        z_ohm        = Float64(mat[i, :Z_OHM]),
        in_service   = mat[i, :IN_SERVICE] != 0,
    )
end

function _unpack_vsc(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    mode_int = Int(mat[i, :MODE])
    mode_sym = mode_int == 1 ? :pq : mode_int == 2 ? :pv : mode_int == 3 ? :vdc_q : :droop
    vsc_type_int = Int(mat[i, :VSC_TYPE])
    vsc_type_str = vsc_type_int == 1 ? "Two-Level" : vsc_type_int == 2 ? "Three-Level" : "MMC"
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:vsc, idx), "")
    VSCConverter(
        # Basic identification
        index        = idx,
        name         = name,
        bus_ac       = Int(mat[i, :ACBUS]),
        bus_dc       = Int(mat[i, :DCBUS]),
        in_service   = mat[i, :INSERVICE] != 0,
        vsc_type     = vsc_type_str,
        # Rated parameters
        p_rated_mw   = Float64(mat[i, :P_RATED_MW]),
        vn_ac_kv     = Float64(mat[i, :VN_AC_KV]),
        vn_dc_kv     = Float64(mat[i, :VN_DC_KV]),
        # Operating state
        p_mw         = Float64(mat[i, :P_AC]),
        q_mvar       = Float64(mat[i, :Q_AC]),
        vm_ac_pu     = Float64(mat[i, :VM_AC_PU]),
        vm_dc_pu     = Float64(mat[i, :VM_DC_PU]),
        # Power limits
        pmax_mw      = Float64(mat[i, :PMAX]),
        pmin_mw      = Float64(mat[i, :PMIN]),
        qmax_mvar    = Float64(mat[i, :QMAX]),
        qmin_mvar    = Float64(mat[i, :QMIN]),
        # Efficiency and losses
        eta          = Float64(mat[i, :EFF]),
        loss_percent = Float64(mat[i, :LOSS_PERCENT]),
        loss_mw      = Float64(mat[i, :LOSS_MW]),
        # Control parameters
        controllable = mat[i, :CONTROLLABLE] != 0,
        control_mode = mode_sym,
        p_set_mw     = Float64(mat[i, :P_SET]),
        q_set_mvar   = Float64(mat[i, :Q_SET]),
        v_ac_set_pu  = Float64(mat[i, :V_AC_SET]),
        v_dc_set_pu  = Float64(mat[i, :V_DC_SET]),
        # Droop control parameters
        k_vdc        = Float64(mat[i, :K_VDC]),
        k_p          = Float64(mat[i, :K_P]),
        k_q          = Float64(mat[i, :K_Q]),
        v_ref_pu     = Float64(mat[i, :V_REF_PU]),
        f_ref_hz     = Float64(mat[i, :F_REF_HZ]),
        # Reliability parameters
        mtbf_hours   = Float64(mat[i, :MTBF_H]),
        mttr_hours   = Float64(mat[i, :MTTR_H]),
        t_scheduled_h = Float64(mat[i, :T_SCHED_H]),
    )
end

function _unpack_dcdc(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    mode_int = Int(mat[i, :MODE])
    mode_sym = mode_int == 1 ? :power : mode_int == 2 ? :voltage : :droop
    idx = Int(mat[i, :INDEX])
    name = get(component_names, (:dcdc, idx), "")
    DCDCConverter(
        # Basic identification
        index           = idx,
        name            = name,
        bus_in          = Int(mat[i, :BUS_IN]),
        bus_out         = Int(mat[i, :BUS_OUT]),
        in_service      = mat[i, :INSERVICE] != 0,
        controllable    = mat[i, :CONTROLLABLE] != 0,
        # Operating state
        v_in_pu         = Float64(mat[i, :V_IN_PU]),
        v_out_pu        = Float64(mat[i, :V_OUT_PU]),
        p_in_mw         = Float64(mat[i, :P_IN_MW]),
        p_out_mw        = Float64(mat[i, :P_OUT_MW]),
        p_ref_mw        = Float64(mat[i, :P_REF_MW]),
        v_ref_pu        = Float64(mat[i, :V_REF_PU]),
        # Rated parameters
        sn_mva          = Float64(mat[i, :SN_MVA]),
        vn_in_kv        = Float64(mat[i, :VN_IN_KV]),
        vn_out_kv       = Float64(mat[i, :VN_OUT_KV]),
        # Efficiency and losses
        eta             = Float64(mat[i, :EFF]),
        r_eq_pu         = Float64(mat[i, :R_EQ_PU]),
        f_switching_khz = Float64(mat[i, :F_SWITCH_KHZ]),
        # Power limits
        pmax_mw         = Float64(mat[i, :PMAX]),
        pmin_mw         = Float64(mat[i, :PMIN]),
        # Control
        control_mode    = mode_sym,
        k_droop         = Float64(mat[i, :K_DROOP]),
        # Reliability parameters
        mtbf_hours      = Float64(mat[i, :MTBF_H]),
        mttr_hours      = Float64(mat[i, :MTTR_H]),
        t_scheduled_h   = Float64(mat[i, :T_SCHED_H]),
    )
end

function _unpack_energy_router(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    mode_int = Int(mat[i, :MODE])
    mode_str = mode_int == 1 ? "PowerDispatch" : mode_int == 2 ? "VoltageControl" : "Droop"
    er_type_int = Int(mat[i, :ER_TYPE])
    er_type_str = er_type_int == 1 ? "3-port" : er_type_int == 2 ? "4-port" : "Multi-port"
    dispatch_int = Int(mat[i, :DISPATCH_STRATEGY])
    dispatch_str = dispatch_int == 1 ? "Proportional" : dispatch_int == 2 ? "Optimal" : "Manual"
    idx = Int(mat[i, :ID])
    name = get(component_names, (:energy_router, idx), "")
    EnergyRouter(
        # Basic identification
        index        = idx,
        name         = name,
        in_service   = mat[i, :INSERVICE] != 0,
        router_type  = er_type_str,
        num_ports    = Int(mat[i, :NUM_PORTS]),
        # Rated parameters
        p_rated_mw   = Float64(mat[i, :P_RATED_MW]),
        vn_ac_kv     = Float64(mat[i, :VN_AC_KV]),
        vn_dc_kv     = Float64(mat[i, :VN_DC_KV]),
        # Loss parameters
        loss_percent = Float64(mat[i, :LOSS_PERCENT]),
        # Control
        control_mode = mode_str,
        power_dispatch_strategy = dispatch_str,
        # Power limits
        pmax_mw      = Float64(mat[i, :PMAX]),
        pmin_mw      = Float64(mat[i, :PMIN]),
        qmax_mvar    = Float64(mat[i, :QMAX]),
        qmin_mvar    = Float64(mat[i, :QMIN]),
        # Voltage limits
        vmax_pu      = Float64(mat[i, :VMAX_PU]),
        vmin_pu      = Float64(mat[i, :VMIN_PU]),
        # Reliability parameters
        mtbf_hours   = Float64(mat[i, :MTBF_H]),
        mttr_hours   = Float64(mat[i, :MTTR_H]),
        t_scheduled_h = Float64(mat[i, :T_SCHED_H]),
        # Economic parameters
        investment_cost = Float64(mat[i, :INVEST_COST]),
        operation_cost_per_mwh = Float64(mat[i, :OP_COST_MWH]),
        maintenance_cost_per_year = Float64(mat[i, :MAINT_COST_YR]),
    )
end

function _unpack_er_port(mat, i, component_names::Dict{Tuple{Symbol, Int}, String})
    port_type_int = Int(mat[i, :PORT_TYPE])
    port_type_sym = port_type_int == 1 ? :ac : :dc
    mode_int = Int(mat[i, :MODE])
    mode_sym = mode_int == 1 ? :p : mode_int == 2 ? :q : mode_int == 3 ? :v : mode_int == 4 ? :pq : mode_int == 5 ? :pv : :vf
    side_int = Int(mat[i, :SIDE])
    side_sym = side_int == 1 ? :primary : :secondary
    idx = Int(mat[i, :ID])
    name = get(component_names, (:er_port, idx), "")
    EnergyRouterPort(
        index           = idx,
        name            = name,
        core_index      = Int(mat[i, :ROUTER_ID]),
        bus             = Int(mat[i, :BUS]),
        port_type       = port_type_sym,
        voltage_level_kv = Float64(mat[i, :VN_KV]),
        # Operating state
        p_ac_mw         = Float64(mat[i, :P_AC_MW]),
        q_ac_mvar       = Float64(mat[i, :Q_AC_MVAR]),
        v_ac_pu         = Float64(mat[i, :V_AC_PU]),
        p_dc_mw         = Float64(mat[i, :P_DC_MW]),
        v_dc_pu         = Float64(mat[i, :V_DC_PU]),
        phi_deg         = Float64(mat[i, :PHI_DEG]),
        # Power limits
        pmax_mw         = Float64(mat[i, :PMAX]),
        pmin_mw         = Float64(mat[i, :PMIN]),
        qmax_mvar       = Float64(mat[i, :QMAX]),
        qmin_mvar       = Float64(mat[i, :QMIN]),
        # Control
        control_mode    = mode_sym,
        p_set_mw        = Float64(mat[i, :P_SET]),
        q_set_mvar      = Float64(mat[i, :Q_SET]),
        v_set_pu        = Float64(mat[i, :V_SET]),
        in_service      = mat[i, :INSERVICE] != 0,
        side            = side_sym,
    )
end
