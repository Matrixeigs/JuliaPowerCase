using Test
using JuliaPowerCase

@testset "Component Types" begin
    # Bus
    b = Bus{AC}(index=1, name="Slack", bus_type=REF_BUS, vm_pu=1.06, base_kv=345.0)
    @test b.vm_pu == 1.06
    @test b.bus_type == REF_BUS
    @test b.in_service == true
    @test b.nc == 1           # New field: customer count
    @test b.omega == 1.0      # New field: importance weight

    # Branch
    br = Branch{AC}(index=1, from_bus=1, to_bus=2, r_pu=0.01, x_pu=0.05)
    @test br.from_bus == 1
    @test br.in_service == true
    @test br.n_parallel == 1  # New field: parallel circuits

    # Generator
    g = Generator(index=1, bus=1, pg_mw=100.0, pmax_mw=200.0, vg_pu=1.05)
    @test g.pg_mw == 100.0
    @test g.in_service == true
    @test g.t_up_min_h == 0.0     # New field: min uptime
    @test g.co2_emission_rate == 0.0  # New field: emissions

    # Load
    l = Load{AC}(index=1, bus=3, p_mw=50.0, q_mvar=20.0)
    @test l.scaling == 1.0
    @test l.controllable == false  # New field
    @test l.priority == 3          # New field

    # Storage (updated field names to match tex spec)
    s = Storage{AC}(index=1, bus=5, p_rated_mw=50.0, e_rated_mwh=100.0)
    @test s.e_rated_mwh == 100.0
    @test s.soh == 100.0           # New field: state of health
    @test s.n_cycle == 6000        # New field: cycle life

    # MobileStorage
    ms = MobileStorage(index=1, p_rated_mw=10.0, e_rated_mwh=40.0)
    @test ms.is_mobile == true     # New field
    @test ms.max_travel_distance_km == 500.0  # New field

    # Switch
    sw = Switch(index=1, bus_from=1, bus_to=2, closed=true)
    @test sw.closed == true
    @test sw.i_rated_ka == 10.0    # New field
    @test sw.mtbf_hours == 87600.0 # New field: reliability

    # DCDCConverter (new type)
    dc_dc = DCDCConverter(index=1, bus_in=1, bus_out=2, sn_mva=10.0)
    @test dc_dc.eta == 0.98        # Efficiency
    @test dc_dc.control_mode == :power

    # VSCConverter (expanded fields)
    vsc = VSCConverter(index=1, bus_ac=1, bus_dc=2, p_rated_mw=100.0)
    @test vsc.vsc_type == "Two-Level"
    @test vsc.mtbf_hours == 8760.0

    # Transformer2W
    t2 = Transformer2W(index=1, hv_bus=1, lv_bus=2, sn_mva=100.0, vn_hv_kv=110.0, vn_lv_kv=10.0)
    @test t2.mtbf_hours == 175200.0  # New field

    # PVSystem
    pv = PVSystem(index=1, bus=1, p_mw=5.0)
    @test pv.mtbf_panel_hours == 175200.0   # New field

    # Type aliases
    @test ACBus === Bus{AC}
    @test DCBus === Bus{DC}
    @test ACBranch === Branch{AC}

    # BusType enum
    @test Int(PQ_BUS) == 1
    @test Int(PV_BUS) == 2
    @test Int(REF_BUS) == 3
    @test Int(ISOLATED_BUS) == 4
end
