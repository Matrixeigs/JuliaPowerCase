using Test
using JuliaPowerCase

@testset "Struct ↔ Matrix Conversion" begin
    # Build a small system from structs
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, vm_pu=1.06, base_kv=230.0))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, pd_mw=20.0, qd_mvar=10.0, base_kv=230.0))
    push!(sys.branches, Branch{AC}(index=1, from_bus=1, to_bus=2, r_pu=0.02, x_pu=0.06))
    push!(sys.generators, Generator(index=1, bus=1, pg_mw=30.0, pmax_mw=100.0, vg_pu=1.06))
    push!(sys.loads, Load{AC}(index=1, bus=2, p_mw=20.0, q_mvar=10.0))

    # to_matrix
    jpc = to_matrix(sys)
    @test nbuses(jpc) == 2
    @test jpc.bus[1, :I] == 1.0
    @test jpc.bus[1, :VM] == 1.06
    @test jpc.branch[1, :F_BUS] == 1.0
    @test jpc.gen[1, :PG] == 30.0

    # from_matrix round-trip
    sys2 = from_matrix(jpc)
    @test length(sys2.buses) == 2
    @test sys2.buses[1].vm_pu == 1.06
    @test sys2.generators[1].pg_mw == 30.0
    @test sys2.loads[1].p_mw == 20.0
end

@testset "Storage Round-Trip Conversion" begin
    # Build system with storage
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, base_kv=110.0))
    
    # Add storage with all critical parameters
    push!(sys.storage, Storage{AC}(
        index = 1,
        bus = 2,
        in_service = true,
        e_rated_mwh = 100.0,
        p_mw = 10.0,
        pmax_mw = 50.0,
        pmin_mw = -50.0,
        eta_charge = 0.95,
        eta_discharge = 0.92,
        soc_min = 0.1,
        soc_max = 0.9,
        soc_init = 0.5
    ))
    
    # Convert to matrix
    jpc = to_matrix(sys)
    @test nstorage(jpc) == 1
    @test jpc.storage[1, :STOR_BUS] == 2.0
    @test jpc.storage[1, :STOR_EMAX] == 100.0
    @test jpc.storage[1, :STOR_PMAX] == 50.0
    @test jpc.storage[1, :STOR_PMIN] == -50.0
    @test jpc.storage[1, :STOR_ETA_CH] == 0.95
    @test jpc.storage[1, :STOR_ETA_DIS] == 0.92
    @test jpc.storage[1, :STOR_SOC_MIN] == 0.1
    @test jpc.storage[1, :STOR_SOC_MAX] == 0.9
    @test jpc.storage[1, :STOR_SOC_INIT] == 0.5
    
    # Convert back and verify
    sys2 = from_matrix(jpc)
    @test length(sys2.storage) == 1
    stor = sys2.storage[1]
    @test stor.bus == 2
    @test stor.e_rated_mwh == 100.0
    @test stor.pmax_mw == 50.0
    @test stor.pmin_mw == -50.0
    @test stor.eta_charge == 0.95
    @test stor.eta_discharge == 0.92
    @test stor.soc_min == 0.1
    @test stor.soc_max == 0.9
    @test stor.soc_init == 0.5
end

@testset "merge_systems Comprehensive" begin
    jpc1 = case5()
    jpc2 = case5()
    
    merged = merge_systems(jpc1, jpc2)
    
    # Verify all components were merged
    @test nbuses(merged) == nbuses(jpc1) + nbuses(jpc2)
    @test nbranches(merged) == nbranches(jpc1) + nbranches(jpc2)
    @test ngenerators(merged) == ngenerators(jpc1) + ngenerators(jpc2)
    
    # Verify bus offset was applied to jpc2 buses
    max_bus1 = maximum(jpc1.bus[i, :I] for i in 1:nbuses(jpc1))
    min_bus2_in_merged = minimum(merged.bus[i, :I] for i in nbuses(jpc1)+1:nbuses(merged))
    @test min_bus2_in_merged > max_bus1
end

@testset "Per-Component Utilities" begin
    jpc = case5()
    @test component_table(jpc, :bus) === jpc.bus
    @test component_table(jpc, :gen) === jpc.gen

    names = component_names(typeof(jpc))
    @test :bus ∈ names
    @test :branch ∈ names

    # slice_buses
    sub = slice_buses(jpc, [1, 2])
    @test nbuses(sub) == 2
end

@testset "Bus Extended Fields Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(
        index = 1,
        bus_type = REF_BUS,
        vm_pu = 1.06,
        va_deg = 0.0,
        base_kv = 230.0,
        pd_mw = 10.0,
        qd_mvar = 5.0,
        gs_mw = 0.1,
        bs_mvar = 0.2,
        vmax_pu = 1.1,
        vmin_pu = 0.9,
        area = 2,
        zone = 3,
        carbon_area = 4,
        carbon_zone = 5,
        nc = 100,  # Number of customers
        omega = 0.8
    ))
    
    jpc = to_matrix(sys)
    @test jpc.bus[1, :CARBON_AREA] == 4.0
    @test jpc.bus[1, :CARBON_ZONE] == 5.0
    @test jpc.bus[1, :PER_CONSUMER] == 100.0
    
    sys2 = from_matrix(jpc)
    b = sys2.buses[1]
    @test b.carbon_area == 4
    @test b.carbon_zone == 5
    @test b.nc == 100
end

@testset "Generator Extended Fields Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=230.0))
    push!(sys.generators, Generator(
        index = 1,
        bus = 1,
        pg_mw = 50.0,
        qg_mvar = 20.0,
        pmax_mw = 100.0,
        pmin_mw = 10.0,
        qmax_mvar = 50.0,
        qmin_mvar = -50.0,
        vg_pu = 1.05,
        mbase_mva = 150.0,
        # Extended: ramp rates
        ramp_agc = 10.0,
        ramp_10 = 15.0,
        ramp_30 = 30.0,
        # Extended: cost
        cost_startup = 1000.0,
        cost_shutdown = 500.0,
        # Extended: emissions
        co2_emission_rate = 0.5,
        # Extended: short-circuit
        vn_kv = 220.0,
        xd_sub_pu = 0.15,
        x_r = 8.0,
        ra_pu = 0.01,
        cos_phi = 0.9,
        xd_pu = 0.25,
        xq_pu = 0.18,
        x0_pu = 0.08
    ))
    
    jpc = to_matrix(sys)
    @test jpc.gen[1, :RAMP_AGC] == 10.0
    @test jpc.gen[1, :RAMP_10] == 15.0
    @test jpc.gen[1, :RAMP_30] == 30.0
    @test jpc.gen[1, :STARTUP] == 1000.0
    @test jpc.gen[1, :SHUTDOWN] == 500.0
    @test jpc.gen[1, :CARBON_EMISSION] == 0.5
    @test jpc.gen[1, :VN_KV] == 220.0
    @test jpc.gen[1, :XD_SUB] == 0.15
    @test jpc.gen[1, :XD] == 0.25
    @test jpc.gen[1, :XQ] == 0.18
    @test jpc.gen[1, :X0] == 0.08
    
    sys2 = from_matrix(jpc)
    g = sys2.generators[1]
    @test g.ramp_agc == 10.0
    @test g.ramp_10 == 15.0
    @test g.ramp_30 == 30.0
    @test g.cost_startup == 1000.0
    @test g.cost_shutdown == 500.0
    @test g.co2_emission_rate == 0.5
    @test g.vn_kv == 220.0
    @test g.xd_sub_pu == 0.15
    @test g.xd_pu == 0.25
    @test g.xq_pu == 0.18
    @test g.x0_pu == 0.08
end

@testset "Branch Extended Fields Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=230.0))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, base_kv=230.0))
    push!(sys.branches, Branch{AC}(
        index = 1,
        from_bus = 1,
        to_bus = 2,
        r_pu = 0.01,
        x_pu = 0.05,
        b_pu = 0.02,
        rate_a_mva = 100.0,
        rate_b_mva = 110.0,
        rate_c_mva = 120.0,
        tap = 1.0,
        shift_deg = 0.0,
        angmin_deg = -30.0,
        angmax_deg = 30.0,
        # Extended: rated
        s_rated_mva = 150.0,
        s_max_mva = 180.0,
        # Extended: reliability
        sw_hours = 0.5,
        rp_hours = 2.0,
        # Extended: zero-sequence
        r0_pu = 0.02,
        x0_pu = 0.1,
        b0_pu = 0.01
    ))
    
    jpc = to_matrix(sys)
    @test jpc.branch[1, :SN_MVA] == 150.0
    @test jpc.branch[1, :MAX_I] == 180.0
    @test jpc.branch[1, :SW_TIME] == 0.5
    @test jpc.branch[1, :RP_TIME] == 2.0
    @test jpc.branch[1, :BR_R0] == 0.02
    @test jpc.branch[1, :BR_X0] == 0.1
    @test jpc.branch[1, :BR_B0] == 0.01
    
    sys2 = from_matrix(jpc)
    br = sys2.branches[1]
    @test br.s_rated_mva == 150.0
    @test br.s_max_mva == 180.0
    @test br.sw_hours == 0.5
    @test br.rp_hours == 2.0
    @test br.r0_pu == 0.02
    @test br.x0_pu == 0.1
    @test br.b0_pu == 0.01
end

@testset "Load Extended Fields Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.loads, Load{AC}(
        index = 1,
        bus = 1,
        p_mw = 50.0,
        q_mvar = 20.0,
        scaling = 0.9,
        # Extended: ZIP model
        const_z_percent = 10.0,
        const_i_percent = 20.0,
        const_p_percent = 70.0,
        # Extended: motor/short-circuit
        sn_mva = 10.0,
        vn_kv = 10.5,
        motor_percent = 30.0,
        lrc = 6.0,
        x_r = 5.0,
        x_sub_pu = 0.15
    ))
    
    jpc = to_matrix(sys)
    @test jpc.load[1, :Z_PERCENT] == 10.0
    @test jpc.load[1, :I_PERCENT] == 20.0
    @test jpc.load[1, :P_PERCENT] == 70.0
    @test jpc.load[1, :SN_MVA] == 10.0
    @test jpc.load[1, :MOTOR_PERCENT] == 30.0
    @test jpc.load[1, :LRC] == 6.0
    @test jpc.load[1, :X_SUB] == 0.15
    
    sys2 = from_matrix(jpc)
    l = sys2.loads[1]
    @test l.const_z_percent == 10.0
    @test l.const_i_percent == 20.0
    @test l.const_p_percent == 70.0
    @test l.sn_mva == 10.0
    @test l.motor_percent == 30.0
    @test l.lrc == 6.0
    @test l.x_sub_pu == 0.15
end

@testset "Storage e_mwh Field Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.storage, Storage{AC}(
        index = 1,
        bus = 1,
        e_rated_mwh = 100.0,
        e_mwh = 45.0,  # Current stored energy
        soc_init = 0.45
    ))
    
    jpc = to_matrix(sys)
    @test jpc.storage[1, :STOR_E_MWH] == 45.0
    @test jpc.storage[1, :STOR_EMAX] == 100.0
    
    sys2 = from_matrix(jpc)
    @test sys2.storage[1].e_mwh == 45.0
    @test sys2.storage[1].e_rated_mwh == 100.0
end

@testset "Switch Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, base_kv=110.0))
    push!(sys.switches, Switch(
        index = 1,
        bus_from = 1,
        bus_to = 2,
        element_type = :line,
        element_id = 1,
        closed = true,
        switch_type = :cb,
        z_ohm = 0.001,
        in_service = true
    ))
    
    jpc = to_matrix(sys)
    @test nrows(jpc.switch) == 1
    @test jpc.switch[1, :BUS_FROM] == 1.0
    @test jpc.switch[1, :BUS_TO] == 2.0
    @test jpc.switch[1, :CLOSED] == 1.0
    
    sys2 = from_matrix(jpc)
    @test length(sys2.switches) == 1
    sw = sys2.switches[1]
    @test sw.bus_from == 1
    @test sw.bus_to == 2
    @test sw.closed == true
    @test sw.switch_type == :cb
end

@testset "VSC Converter Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.vsc_converters, VSCConverter(
        index = 1,
        bus_ac = 1,
        bus_dc = 101,
        p_mw = 50.0,
        q_mvar = 20.0,
        eta = 0.98,
        control_mode = :pq,
        k_p = 0.05,
        pmax_mw = 100.0,
        in_service = true
    ))
    
    jpc = to_matrix(sys)
    @test nrows(jpc.converter) == 1
    @test jpc.converter[1, :ACBUS] == 1.0
    @test jpc.converter[1, :DCBUS] == 101.0
    @test jpc.converter[1, :P_AC] == 50.0
    @test jpc.converter[1, :EFF] == 0.98
    
    sys2 = from_matrix(jpc)
    @test length(sys2.vsc_converters) == 1
    @test length(sys2.converters) == 1  # Legacy field also populated
    c = sys2.vsc_converters[1]
    @test c.bus_ac == 1
    @test c.bus_dc == 101
    @test c.p_mw == 50.0
    @test c.eta == 0.98
    @test c.control_mode == :pq
end

@testset "nconverters counts all types" begin
    sys = PowerSystem{AC}()
    push!(sys.vsc_converters, VSCConverter(index=1, bus_ac=1, bus_dc=101))
    push!(sys.vsc_converters, VSCConverter(index=2, bus_ac=2, bus_dc=102))
    push!(sys.dcdc_converters, DCDCConverter(index=1, bus_in=101, bus_out=102))
    
    @test nvsc_converters(sys) == 2
    @test ndcdc_converters(sys) == 1
    @test nconverters(sys) == 3  # Total: 2 VSC + 1 DCDC + 0 ER
end

@testset "VSC Full Field Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.vsc_converters, VSCConverter(
        index = 42,
        name = "VSC1",  # Name preserved via sidecar dict
        bus_ac = 1,
        bus_dc = 101,
        in_service = true,
        vsc_type = "MMC",
        p_rated_mw = 500.0,
        vn_ac_kv = 220.0,
        vn_dc_kv = 400.0,
        p_mw = 150.0,
        q_mvar = 50.0,
        vm_ac_pu = 1.02,
        vm_dc_pu = 1.01,
        pmax_mw = 600.0,
        pmin_mw = -600.0,
        qmax_mvar = 300.0,
        qmin_mvar = -300.0,
        eta = 0.985,
        loss_percent = 1.5,
        loss_mw = 2.25,
        controllable = true,
        control_mode = :droop,
        p_set_mw = 100.0,
        q_set_mvar = 25.0,
        v_ac_set_pu = 1.0,
        v_dc_set_pu = 1.0,
        k_vdc = 0.1,
        k_p = 0.05,
        k_q = 0.02,
        v_ref_pu = 1.0,
        f_ref_hz = 50.0,
        mtbf_hours = 5000.0,
        mttr_hours = 48.0,
        t_scheduled_h = 720.0,  # Scheduled maintenance interval
    ))
    
    jpc = to_matrix(sys)
    sys2 = from_matrix(jpc)
    c = sys2.vsc_converters[1]
    
    @test c.index == 42
    @test c.vsc_type == "MMC"
    @test c.vn_ac_kv == 220.0
    @test c.vn_dc_kv == 400.0
    @test c.mtbf_hours == 5000.0
    @test c.mttr_hours == 48.0
    @test c.t_scheduled_h == 720.0  # Verify t_scheduled_h round-trip
    @test c.k_vdc == 0.1
    @test c.control_mode == :droop
end

@testset "DCDC Full Field Round-Trip" begin
    sys = PowerSystem{DC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{DC}(index=1, base_kv=400.0))
    push!(sys.buses, Bus{DC}(index=2, base_kv=200.0))
    push!(sys.dcdc_converters, DCDCConverter(
        index = 7,
        bus_in = 1,
        bus_out = 2,
        in_service = true,
        controllable = true,
        v_in_pu = 1.01,
        v_out_pu = 0.99,
        p_in_mw = 100.0,
        p_out_mw = 98.5,
        p_ref_mw = 100.0,
        v_ref_pu = 1.0,
        sn_mva = 150.0,
        vn_in_kv = 400.0,
        vn_out_kv = 200.0,
        eta = 0.985,
        r_eq_pu = 0.02,
        f_switching_khz = 15.0,
        pmax_mw = 200.0,
        pmin_mw = 0.0,
        control_mode = :droop,
        k_droop = 0.05,
        mtbf_hours = 10000.0,
        mttr_hours = 12.0,
        t_scheduled_h = 480.0,  # Scheduled maintenance interval
    ))
    
    jpc = to_matrix(sys)
    sys2 = from_matrix(jpc)
    dc = sys2.dcdc_converters[1]
    
    @test dc.index == 7
    @test dc.controllable == true
    @test dc.f_switching_khz == 15.0
    @test dc.mtbf_hours == 10000.0
    @test dc.mttr_hours == 12.0
    @test dc.t_scheduled_h == 480.0  # Verify t_scheduled_h round-trip
    @test dc.control_mode == :droop
end

@testset "EnergyRouter Full Field Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.energy_routers, EnergyRouter(
        index = 3,
        in_service = true,
        router_type = "4-port",
        num_ports = 4,
        p_rated_mw = 50.0,
        vn_ac_kv = 110.0,
        vn_dc_kv = 400.0,
        loss_percent = 2.0,
        control_mode = "VoltageControl",
        power_dispatch_strategy = "Optimal",
        pmax_mw = 60.0,
        pmin_mw = -60.0,
        qmax_mvar = 30.0,
        qmin_mvar = -30.0,
        vmax_pu = 1.05,
        vmin_pu = 0.95,
        mtbf_hours = 20000.0,
        mttr_hours = 72.0,
        t_scheduled_h = 100.0,
        investment_cost = 500.0,
        operation_cost_per_mwh = 2.5,  # Economic parameter
        maintenance_cost_per_year = 10.0,  # Economic parameter
    ))
    
    jpc = to_matrix(sys)
    sys2 = from_matrix(jpc)
    er = sys2.energy_routers[1]
    
    @test er.index == 3
    @test er.router_type == "4-port"
    @test er.control_mode == "VoltageControl"
    @test er.power_dispatch_strategy == "Optimal"
    @test er.mtbf_hours == 20000.0
    @test er.t_scheduled_h == 100.0
    @test er.investment_cost == 500.0
    @test er.operation_cost_per_mwh == 2.5
    @test er.maintenance_cost_per_year == 10.0
end

@testset "EnergyRouterPort Round-Trip" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.buses, Bus{AC}(index=2, bus_type=PQ_BUS, base_kv=110.0))
    
    # Create ports
    port1 = EnergyRouterPort(
        index = 101,
        core_index = 3,
        bus = 1,
        port_type = :ac,
        voltage_level_kv = 110.0,
        p_ac_mw = 10.0,
        q_ac_mvar = 5.0,
        v_ac_pu = 1.02,
        p_dc_mw = 0.0,
        v_dc_pu = 1.0,
        phi_deg = 30.0,
        pmax_mw = 50.0,
        pmin_mw = -50.0,
        qmax_mvar = 30.0,
        qmin_mvar = -30.0,
        control_mode = :pq,
        p_set_mw = 10.0,
        q_set_mvar = 5.0,
        v_set_pu = 1.0,
        in_service = true,
        side = :primary,
    )
    port2 = EnergyRouterPort(
        index = 102,
        core_index = 3,
        bus = 2,
        port_type = :dc,
        voltage_level_kv = 400.0,
        p_ac_mw = 0.0,
        q_ac_mvar = 0.0,
        v_ac_pu = 1.0,
        p_dc_mw = 8.0,
        v_dc_pu = 1.01,
        phi_deg = 0.0,
        pmax_mw = 40.0,
        pmin_mw = -40.0,
        qmax_mvar = 0.0,
        qmin_mvar = 0.0,
        control_mode = :v,
        p_set_mw = 0.0,
        q_set_mvar = 0.0,
        v_set_pu = 1.01,
        in_service = true,
        side = :secondary,
    )
    
    # Create energy router with ports
    er = EnergyRouter(
        index = 3,
        in_service = true,
        router_type = "3-port",
        num_ports = 2,
        ports = [port1, port2],
    )
    push!(sys.energy_routers, er)
    
    jpc = to_matrix(sys)
    @test nrows(jpc.er_port) == 2
    
    sys2 = from_matrix(jpc)
    @test length(sys2.energy_routers) == 1
    er2 = sys2.energy_routers[1]
    @test length(er2.ports) == 2
    
    # Verify ports are correctly restored
    p1 = er2.ports[1]
    @test p1.index == 101
    @test p1.core_index == 3
    @test p1.bus == 1
    @test p1.port_type == :ac
    @test p1.voltage_level_kv == 110.0
    @test p1.p_ac_mw == 10.0
    @test p1.q_ac_mvar == 5.0
    @test p1.control_mode == :pq
    @test p1.side == :primary
    
    p2 = er2.ports[2]
    @test p2.index == 102
    @test p2.port_type == :dc
    @test p2.voltage_level_kv == 400.0
    @test p2.p_dc_mw == 8.0
    @test p2.v_dc_pu == 1.01
    @test p2.control_mode == :v
    @test p2.side == :secondary
end

@testset "merge_systems sgen bus offset correct" begin
    jpc1 = case5()  # Buses 1-5
    jpc2 = case5()  # Buses 1-5, will be offset to 1001-1005
    
    # Add sgen to both systems with explicit ID and BUS
    jpc1.sgen = ComponentMatrix{SgenSchema, Float64}(1)
    jpc1.sgen[1, :ID] = 1.0
    jpc1.sgen[1, :BUS] = 3.0   # Bus 3 in jpc1
    jpc1.sgen[1, :P_MW] = 10.0
    
    jpc2.sgen = ComponentMatrix{SgenSchema, Float64}(1)
    jpc2.sgen[1, :ID] = 2.0
    jpc2.sgen[1, :BUS] = 4.0   # Bus 4 in jpc2
    jpc2.sgen[1, :P_MW] = 15.0
    
    merged = merge_systems(jpc1, jpc2)
    
    @test nrows(merged.sgen) == 2
    # First sgen should be unchanged
    @test merged.sgen[1, :ID] == 1.0
    @test merged.sgen[1, :BUS] == 3.0
    # Second sgen: ID unchanged, BUS offset by 1000
    @test merged.sgen[2, :ID] == 2.0   # ID should NOT be offset
    @test merged.sgen[2, :BUS] == 1004.0  # BUS should be offset
end

@testset "merge_systems preserves all tables" begin
    jpc1 = case5()
    jpc2 = case5()
    
    # Add dcdc to both
    jpc1.dcdc = ComponentMatrix{DCDCSchema, Float64}(1)
    jpc1.dcdc[1, :INDEX] = 1.0
    jpc1.dcdc[1, :BUS_IN] = 1.0
    jpc1.dcdc[1, :BUS_OUT] = 2.0
    
    jpc2.dcdc = ComponentMatrix{DCDCSchema, Float64}(1)
    jpc2.dcdc[1, :INDEX] = 2.0
    jpc2.dcdc[1, :BUS_IN] = 3.0
    jpc2.dcdc[1, :BUS_OUT] = 4.0
    
    # Add energy_router to both
    jpc1.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc1.energy_router[1, :ID] = 1.0
    jpc1.energy_router[1, :NUM_PORTS] = 3.0
    
    jpc2.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc2.energy_router[1, :ID] = 2.0
    jpc2.energy_router[1, :NUM_PORTS] = 4.0
    
    # Add trafo3w (need proper columns)
    jpc1.trafo3w = ComponentMatrix{Trafo3WSchema, Float64}(1)
    jpc1.trafo3w[1, :HV_BUS] = 1.0
    jpc1.trafo3w[1, :MV_BUS] = 2.0
    jpc1.trafo3w[1, :LV_BUS] = 3.0
    
    jpc2.trafo3w = ComponentMatrix{Trafo3WSchema, Float64}(1)
    jpc2.trafo3w[1, :HV_BUS] = 1.0
    jpc2.trafo3w[1, :MV_BUS] = 4.0
    jpc2.trafo3w[1, :LV_BUS] = 5.0
    
    merged = merge_systems(jpc1, jpc2)
    
    # Check dcdc merged correctly
    @test nrows(merged.dcdc) == 2
    @test merged.dcdc[2, :BUS_IN] == 1003.0  # offset
    @test merged.dcdc[2, :BUS_OUT] == 1004.0  # offset
    
    # Check energy_router merged
    @test nrows(merged.energy_router) == 2
    
    # Check trafo3w merged
    @test nrows(merged.trafo3w) == 2
    @test merged.trafo3w[2, :HV_BUS] == 1001.0
    @test merged.trafo3w[2, :MV_BUS] == 1004.0
    @test merged.trafo3w[2, :LV_BUS] == 1005.0
end

@testset "component_table supports dcdc and energy_router" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.dcdc = ComponentMatrix{DCDCSchema, Float64}(2)
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(3)
    
    dcdc_table = component_table(jpc, :dcdc)
    @test nrows(dcdc_table) == 2
    
    er_table = component_table(jpc, :energy_router)
    @test nrows(er_table) == 3
    
    # Check component_names includes new types
    names = component_names(PowerCaseData)
    @test :dcdc ∈ names
    @test :energy_router ∈ names
end

@testset "nconverters for PowerCaseData counts all types" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.converter = ComponentMatrix{ConverterSchema, Float64}(2)
    jpc.dcdc = ComponentMatrix{DCDCSchema, Float64}(3)
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    
    @test nvsc_converters(jpc) == 2
    @test ndcdc_converters(jpc) == 3
    @test nenergy_routers(jpc) == 1
    @test nconverters(jpc) == 6  # 2 + 3 + 1
end

@testset "slice_buses preserves all element types" begin
    jpc = case5()
    
    # Add sgen
    jpc.sgen = ComponentMatrix{SgenSchema, Float64}(2)
    jpc.sgen[1, :ID] = 1.0; jpc.sgen[1, :BUS] = 1.0; jpc.sgen[1, :P_MW] = 10.0
    jpc.sgen[2, :ID] = 2.0; jpc.sgen[2, :BUS] = 5.0; jpc.sgen[2, :P_MW] = 20.0
    
    # Add storage
    jpc.storage = ComponentMatrix{StorageSchema, Float64}(1)
    jpc.storage[1, :STOR_BUS] = 2.0
    
    # Add converter (VSC)
    jpc.converter = ComponentMatrix{ConverterSchema, Float64}(1)
    jpc.converter[1, :ACBUS] = 1.0
    jpc.converter[1, :DCBUS] = 3.0  # Both in slice
    
    # Slice to buses 1, 2, 3
    sub = slice_buses(jpc, [1, 2, 3])
    
    # Check buses
    @test nrows(sub.bus) == 3
    
    # Check sgen: only bus 1 should be in result
    @test nrows(sub.sgen) == 1
    @test sub.sgen[1, :BUS] == 1.0
    
    # Check storage: bus 2 should be in result
    @test nrows(sub.storage) == 1
    
    # Check converter: both buses 1 and 3 are in slice
    @test nrows(sub.converter) == 1
end

@testset "merge_systems ER/ERPort ID remapping no collision" begin
    # Regression test: merge_systems should use max(ID)+offset, not bus offset
    # to avoid ID collisions when two systems have overlapping ER IDs
    jpc1 = PowerCaseData{AC, Float64}()
    jpc1.base_mva = 100.0
    jpc1.bus = ComponentMatrix{BusSchema, Float64}(2)
    jpc1.bus[1, :I] = 1.0
    jpc1.bus[1, :TYPE] = 3.0  # REF_BUS
    jpc1.bus[2, :I] = 2.0
    jpc1.bus[2, :TYPE] = 1.0  # PQ_BUS
    
    jpc2 = PowerCaseData{AC, Float64}()
    jpc2.base_mva = 100.0
    jpc2.bus = ComponentMatrix{BusSchema, Float64}(2)
    jpc2.bus[1, :I] = 1.0
    jpc2.bus[1, :TYPE] = 3.0  # REF_BUS
    jpc2.bus[2, :I] = 2.0
    jpc2.bus[2, :TYPE] = 1.0  # PQ_BUS
    
    # Both systems have ER with ID=1 - previously this would cause collision
    jpc1.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc1.energy_router[1, :ID] = 1.0
    jpc1.energy_router[1, :NUM_PORTS] = 2.0
    
    jpc2.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc2.energy_router[1, :ID] = 1.0  # Same ID as jpc1
    jpc2.energy_router[1, :NUM_PORTS] = 2.0
    
    # Add ports for both ERs
    jpc1.er_port = ComponentMatrix{ERPortSchema, Float64}(2)
    jpc1.er_port[1, :ID] = 101.0
    jpc1.er_port[1, :ROUTER_ID] = 1.0
    jpc1.er_port[1, :BUS] = 1.0
    jpc1.er_port[2, :ID] = 102.0
    jpc1.er_port[2, :ROUTER_ID] = 1.0
    jpc1.er_port[2, :BUS] = 2.0
    
    jpc2.er_port = ComponentMatrix{ERPortSchema, Float64}(2)
    jpc2.er_port[1, :ID] = 201.0
    jpc2.er_port[1, :ROUTER_ID] = 1.0  # References ER ID=1 in jpc2
    jpc2.er_port[1, :BUS] = 1.0
    jpc2.er_port[2, :ID] = 202.0
    jpc2.er_port[2, :ROUTER_ID] = 1.0
    jpc2.er_port[2, :BUS] = 2.0
    
    merged = merge_systems(jpc1, jpc2)
    
    # ERs should have unique IDs after merge
    @test nrows(merged.energy_router) == 2
    er_id1 = merged.energy_router[1, :ID]
    er_id2 = merged.energy_router[2, :ID]
    @test er_id1 != er_id2  # IDs must be unique
    @test er_id1 == 1.0     # First ER keeps original ID
    @test er_id2 == 2.0     # Second ER gets remapped (max_id1 + 1)
    
    # Ports should have consistent ROUTER_ID references
    @test nrows(merged.er_port) == 4
    # First 2 ports should reference ER ID=1
    @test merged.er_port[1, :ROUTER_ID] == 1.0
    @test merged.er_port[2, :ROUTER_ID] == 1.0
    # Last 2 ports should reference ER ID=2 (remapped)
    @test merged.er_port[3, :ROUTER_ID] == 2.0
    @test merged.er_port[4, :ROUTER_ID] == 2.0
    
    # Convert to PowerSystem and verify ports are correctly assigned
    sys = from_matrix(merged)
    @test length(sys.energy_routers) == 2
    @test length(sys.energy_routers[1].ports) == 2
    @test length(sys.energy_routers[2].ports) == 2
end

@testset "Port core_index derived from parent router" begin
    # Regression test: ports with default core_index=0 should still round-trip
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    
    # Create port without setting core_index (default=0)
    port = EnergyRouterPort(
        index = 1,
        bus = 1,
        # core_index = 0  # default, not set
    )
    
    # Create router with this port
    er = EnergyRouter(
        index = 42,  # Non-zero router index
        ports = [port],
    )
    push!(sys.energy_routers, er)
    
    # Round-trip
    jpc = to_matrix(sys)
    @test nrows(jpc.er_port) == 1
    @test jpc.er_port[1, :ROUTER_ID] == 42.0  # Should use parent's index, not port's core_index
    
    sys2 = from_matrix(jpc)
    @test length(sys2.energy_routers) == 1
    @test length(sys2.energy_routers[1].ports) == 1  # Port should be assigned to router
    @test sys2.energy_routers[1].ports[1].core_index == 42
end

@testset "slice_buses updates NUM_PORTS correctly" begin
    # Regression test: after slice_buses, NUM_PORTS should match actual retained ports
    jpc = PowerCaseData{AC, Float64}()
    jpc.base_mva = 100.0
    jpc.bus = ComponentMatrix{BusSchema, Float64}(4)
    jpc.bus[1, :I] = 1.0
    jpc.bus[1, :TYPE] = 3.0  # REF_BUS
    jpc.bus[2, :I] = 2.0
    jpc.bus[2, :TYPE] = 1.0  # PQ_BUS
    jpc.bus[3, :I] = 3.0
    jpc.bus[3, :TYPE] = 1.0  # PQ_BUS
    jpc.bus[4, :I] = 4.0
    jpc.bus[4, :TYPE] = 1.0  # PQ_BUS
    
    # Add energy router with 3 ports on buses 1, 2, 4
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc.energy_router[1, :ID] = 1.0
    jpc.energy_router[1, :NUM_PORTS] = 3.0
    
    jpc.er_port = ComponentMatrix{ERPortSchema, Float64}(3)
    jpc.er_port[1, :ID] = 1.0
    jpc.er_port[1, :ROUTER_ID] = 1.0
    jpc.er_port[1, :BUS] = 1.0
    jpc.er_port[2, :ID] = 2.0
    jpc.er_port[2, :ROUTER_ID] = 1.0
    jpc.er_port[2, :BUS] = 2.0
    jpc.er_port[3, :ID] = 3.0
    jpc.er_port[3, :ROUTER_ID] = 1.0
    jpc.er_port[3, :BUS] = 4.0  # Bus 4 will be excluded from slice
    
    # Slice to buses 1 and 2 only
    sub = slice_buses(jpc, [1, 2])
    
    # Only 2 ports should remain
    @test nrows(sub.er_port) == 2
    # Router NUM_PORTS should be updated to 2
    @test nrows(sub.energy_router) == 1
    @test sub.energy_router[1, :NUM_PORTS] == 2.0
    
    # Verify round-trip produces correct port count
    sys = from_matrix(sub)
    @test length(sys.energy_routers) == 1
    @test sys.energy_routers[1].num_ports == 2
    @test length(sys.energy_routers[1].ports) == 2
end

@testset "Component Name Round-Trip (Sidecar)" begin
    # Test VSC name round-trip
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.vsc_converters, VSCConverter(
        index = 1, name = "VSC_Station_Alpha", bus_ac = 1, bus_dc = 101,
    ))
    push!(sys.dcdc_converters, DCDCConverter(
        index = 2, name = "DCDC_Buck_Unit_1", bus_in = 101, bus_out = 102,
    ))
    push!(sys.energy_routers, EnergyRouter(
        index = 3, name = "ER_Central_Hub",
        ports = [
            EnergyRouterPort(index = 31, name = "ER3_Port_AC", core_index = 3, bus = 1, port_type = :ac),
            EnergyRouterPort(index = 32, name = "ER3_Port_DC", core_index = 3, bus = 101, port_type = :dc),
        ],
    ))
    
    jpc = to_matrix(sys)
    
    # Verify names stored in sidecar
    @test haskey(jpc.component_names, (:vsc, 1))
    @test jpc.component_names[(:vsc, 1)] == "VSC_Station_Alpha"
    @test jpc.component_names[(:dcdc, 2)] == "DCDC_Buck_Unit_1"
    @test jpc.component_names[(:energy_router, 3)] == "ER_Central_Hub"
    @test jpc.component_names[(:er_port, 31)] == "ER3_Port_AC"
    @test jpc.component_names[(:er_port, 32)] == "ER3_Port_DC"
    
    # Round-trip and verify names restored
    sys2 = from_matrix(jpc)
    @test sys2.vsc_converters[1].name == "VSC_Station_Alpha"
    @test sys2.dcdc_converters[1].name == "DCDC_Buck_Unit_1"
    @test sys2.energy_routers[1].name == "ER_Central_Hub"
    @test sys2.energy_routers[1].ports[1].name == "ER3_Port_AC"
    @test sys2.energy_routers[1].ports[2].name == "ER3_Port_DC"
end

@testset "Empty Name Round-Trip" begin
    # Components without name should still work
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.vsc_converters, VSCConverter(index = 1, bus_ac = 1, bus_dc = 101))  # no name
    
    jpc = to_matrix(sys)
    @test !haskey(jpc.component_names, (:vsc, 1))  # Empty names not stored
    
    sys2 = from_matrix(jpc)
    @test sys2.vsc_converters[1].name == ""  # Default empty string
end

@testset "validate_case - Valid Case" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(2)
    jpc.bus[1, :I] = 1.0
    jpc.bus[2, :I] = 2.0
    
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc.energy_router[1, :ID] = 1.0
    jpc.energy_router[1, :NUM_PORTS] = 2.0
    
    jpc.er_port = ComponentMatrix{ERPortSchema, Float64}(2)
    jpc.er_port[1, :ID] = 101.0
    jpc.er_port[1, :ROUTER_ID] = 1.0
    jpc.er_port[2, :ID] = 102.0
    jpc.er_port[2, :ROUTER_ID] = 1.0
    
    errors = validate_case(jpc)
    @test isempty(errors)
    @test is_valid(jpc)
end

@testset "validate_case - Duplicate ER IDs" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(1)
    jpc.bus[1, :I] = 1.0
    
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(2)
    jpc.energy_router[1, :ID] = 1.0  # Duplicate
    jpc.energy_router[2, :ID] = 1.0  # Duplicate
    
    errors = validate_case(jpc)
    @test length(errors) >= 1
    @test any(e -> e.level == :error && occursin("Duplicate", e.message), errors)
    @test !is_valid(jpc)
end

@testset "validate_case - Invalid ROUTER_ID Reference" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(1)
    jpc.bus[1, :I] = 1.0
    
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc.energy_router[1, :ID] = 1.0
    
    jpc.er_port = ComponentMatrix{ERPortSchema, Float64}(1)
    jpc.er_port[1, :ID] = 101.0
    jpc.er_port[1, :ROUTER_ID] = 999.0  # Non-existent router
    
    errors = validate_case(jpc)
    @test length(errors) >= 1
    @test any(e -> e.level == :error && occursin("non-existent ROUTER_ID", e.message), errors)
end

@testset "validate_case - NUM_PORTS Mismatch" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(1)
    jpc.bus[1, :I] = 1.0
    
    jpc.energy_router = ComponentMatrix{ERSchema, Float64}(1)
    jpc.energy_router[1, :ID] = 1.0
    jpc.energy_router[1, :NUM_PORTS] = 5.0  # Declared 5 but only 2 exist
    
    jpc.er_port = ComponentMatrix{ERPortSchema, Float64}(2)
    jpc.er_port[1, :ID] = 101.0
    jpc.er_port[1, :ROUTER_ID] = 1.0
    jpc.er_port[2, :ID] = 102.0
    jpc.er_port[2, :ROUTER_ID] = 1.0
    
    errors = validate_case(jpc)
    @test length(errors) >= 1
    @test any(e -> e.level == :warning && occursin("NUM_PORTS", e.message), errors)
    # Warnings don't make is_valid return false
    @test is_valid(jpc)
    @test has_warnings(jpc)
end

@testset "component_names preserved in merge_systems" begin
    # Create two systems with named converters
    jpc1 = PowerCaseData{AC, Float64}()
    jpc1.bus = ComponentMatrix{BusSchema, Float64}(1)
    jpc1.bus[1, :I] = 1.0
    jpc1.converter = ComponentMatrix{ConverterSchema, Float64}(1)
    jpc1.converter[1, :INDEX] = 1.0
    jpc1.component_names[(:vsc, 1)] = "VSC_System1"
    
    jpc2 = PowerCaseData{AC, Float64}()
    jpc2.bus = ComponentMatrix{BusSchema, Float64}(1)
    jpc2.bus[1, :I] = 1.0
    jpc2.converter = ComponentMatrix{ConverterSchema, Float64}(1)
    jpc2.converter[1, :INDEX] = 2.0
    jpc2.component_names[(:vsc, 2)] = "VSC_System2"
    
    merged = merge_systems(jpc1, jpc2)
    
    # Names should be preserved (jpc2's VSC index 2 gets offset by max(jpc1 indices)=1 to become 3)
    @test haskey(merged.component_names, (:vsc, 1))
    @test merged.component_names[(:vsc, 1)] == "VSC_System1"
    @test haskey(merged.component_names, (:vsc, 3))  # 2 + offset(1) = 3
    @test merged.component_names[(:vsc, 3)] == "VSC_System2"
end

@testset "component_names preserved in slice_buses" begin
    jpc = PowerCaseData{AC, Float64}()
    jpc.bus = ComponentMatrix{BusSchema, Float64}(3)
    jpc.bus[1, :I] = 1.0
    jpc.bus[2, :I] = 2.0
    jpc.bus[3, :I] = 3.0
    
    # Converter on bus 1 and 2
    jpc.converter = ComponentMatrix{ConverterSchema, Float64}(2)
    jpc.converter[1, :INDEX] = 10.0
    jpc.converter[1, :ACBUS] = 1.0
    jpc.converter[1, :DCBUS] = 2.0
    jpc.converter[2, :INDEX] = 20.0
    jpc.converter[2, :ACBUS] = 2.0
    jpc.converter[2, :DCBUS] = 3.0
    
    jpc.component_names[(:vsc, 10)] = "VSC_Retained"
    jpc.component_names[(:vsc, 20)] = "VSC_Removed"
    
    # Slice to buses 1 and 2 only - VSC_Removed should be gone
    sub = slice_buses(jpc, [1, 2])
    
    @test haskey(sub.component_names, (:vsc, 10))
    @test sub.component_names[(:vsc, 10)] == "VSC_Retained"
    @test !haskey(sub.component_names, (:vsc, 20))  # Removed (bus 3 not in slice)
end

@testset "component_names preserved in save/load_julia_case" begin
    sys = PowerSystem{AC}()
    sys.base_mva = 100.0
    push!(sys.buses, Bus{AC}(index=1, bus_type=REF_BUS, base_kv=110.0))
    push!(sys.vsc_converters, VSCConverter(index=1, name="TestVSC", bus_ac=1, bus_dc=101))
    
    jpc = to_matrix(sys)
    @test haskey(jpc.component_names, (:vsc, 1))
    
    # Save and reload
    tmpfile = tempname() * ".jl"
    save_julia_case(tmpfile, jpc)
    jpc2 = load_julia_case(tmpfile)
    rm(tmpfile)
    
    # Names should survive round-trip
    @test haskey(jpc2.component_names, (:vsc, 1))
    @test jpc2.component_names[(:vsc, 1)] == "TestVSC"
end
