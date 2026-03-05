# ═══════════════════════════════════════════════════════════════════════════════
# IEEE Distribution Test Cases
# ═══════════════════════════════════════════════════════════════════════════════

"""
    case_ieee13(; T=Float64) -> PowerCaseData{AC,T}

IEEE 13-bus distribution test feeder (simplified single-phase equivalent).
13 buses, 12 branches (radial), 1 substation source + loads.
"""
function case_ieee13(; T::Type{<:Real}=Float64)
    jpc = PowerCaseData{AC, T}()
    jpc.name = "IEEE 13-bus distribution feeder"
    jpc.base_mva = T(10)
    jpc.base_kv  = T(4.16)

    # 13 buses: bus 650 is substation (REF), rest are PQ loads
    bus_data = zeros(T, 13, ncols(BusSchema))
    bus_ids = [650, 632, 633, 634, 645, 646, 671, 680, 684, 611, 652, 692, 675]
    bus_types = [3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]  # 3=REF
    pd = [0, 0, 0, 160, 0, 230, 385, 0, 0, 170, 128, 0, 485]
    qd = [0, 0, 0, 110, 0, 132, 220, 0, 0, 80, 86, 0, 190]
    for i in 1:13
        bus_data[i, 1] = bus_ids[i]
        bus_data[i, 2] = bus_types[i]
        bus_data[i, 3] = pd[i] / 1000  # kW → MW
        bus_data[i, 4] = qd[i] / 1000
        bus_data[i, 7] = 1   # area
        bus_data[i, 8] = 1.0 # VM
        bus_data[i, 10] = 4.16  # base kV
        bus_data[i, 11] = 1   # zone
        bus_data[i, 12] = 1.05  # vmax
        bus_data[i, 13] = 0.95  # vmin
    end
    jpc.bus = ComponentMatrix{BusSchema, T}(bus_data)

    # 12 radial branches (INDEX is column 1, F_BUS is column 2, T_BUS is column 3)
    branch_pairs = [
        (650,632), (632,633), (633,634), (632,645), (645,646),
        (632,671), (671,680), (671,684), (684,611), (684,652),
        (671,692), (692,675)
    ]
    br_data = zeros(T, 12, ncols(BranchSchema))
    for (i, (f, t)) in enumerate(branch_pairs)
        br_data[i, 1] = i     # INDEX
        br_data[i, 2] = f     # F_BUS
        br_data[i, 3] = t     # T_BUS
        br_data[i, 4] = 0.01  # r
        br_data[i, 5] = 0.04  # x
        br_data[i, 7] = 10    # rate_a
        br_data[i, 12] = 1    # status
        br_data[i, 13] = -360; br_data[i, 14] = 360
    end
    jpc.branch = ComponentMatrix{BranchSchema, T}(br_data)

    # Substation generator at bus 650 (INDEX is column 1, GEN_BUS is column 2)
    gen_data = zeros(T, 1, ncols(GenSchema))
    gen_data[1, 1] = 1      # INDEX
    gen_data[1, 2] = 650    # GEN_BUS
    gen_data[1, 7] = 1.0    # VG
    gen_data[1, 8] = 10     # MBASE
    gen_data[1, 9] = 1      # STATUS
    gen_data[1, 10] = 10    # PMAX
    gen_data[1, 5] = 10     # QMAX
    gen_data[1, 6] = -10    # QMIN
    jpc.gen = ComponentMatrix{GenSchema, T}(gen_data)

    return jpc
end


"""
    case_ieee33(; T=Float64) -> PowerCaseData{AC,T}

IEEE 33-bus radial distribution system.
33 buses, 32 branches, 1 substation + distributed loads.
"""
function case_ieee33(; T::Type{<:Real}=Float64)
    jpc = PowerCaseData{AC, T}()
    jpc.name = "IEEE 33-bus distribution"
    jpc.base_mva = T(10)
    jpc.base_kv  = T(12.66)

    # Load data (kW, kVar) for buses 1..33
    pd_kw = [0, 100, 90, 120, 60, 60, 200, 200, 60, 60,
             45, 60, 60, 120, 60, 60, 60, 90, 90, 90,
             90, 90, 90, 420, 420, 60, 60, 60, 120, 200,
             150, 210, 60]
    qd_kvar = [0, 60, 40, 80, 30, 20, 100, 100, 20, 20,
               30, 35, 35, 80, 10, 20, 20, 40, 40, 40,
               40, 40, 50, 200, 200, 25, 25, 20, 70, 600,
               70, 100, 40]

    bus_data = zeros(T, 33, ncols(BusSchema))
    for i in 1:33
        bus_data[i, 1] = i                    # bus number
        bus_data[i, 2] = (i == 1) ? 3 : 1    # REF at bus 1
        bus_data[i, 3] = pd_kw[i] / 1000     # MW
        bus_data[i, 4] = qd_kvar[i] / 1000   # MVar
        bus_data[i, 7] = 1; bus_data[i, 8] = 1.0
        bus_data[i, 10] = 12.66; bus_data[i, 11] = 1
        bus_data[i, 12] = 1.05; bus_data[i, 13] = 0.95
    end
    jpc.bus = ComponentMatrix{BusSchema, T}(bus_data)

    # 32 radial branches (main feeder + laterals)
    from_buses = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                  17, 2, 19, 20, 21, 3, 23, 24, 6, 26, 27, 28, 29, 30, 31, 32]
    to_buses   = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17,
                  18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]
    br_data = zeros(T, 32, ncols(BranchSchema))
    for i in 1:32
        br_data[i, 1] = i                # INDEX
        br_data[i, 2] = from_buses[i]    # F_BUS
        br_data[i, 3] = to_buses[i]      # T_BUS
        br_data[i, 4] = 0.01   # typical r
        br_data[i, 5] = 0.02   # typical x
        br_data[i, 7] = 10     # rate_a
        br_data[i, 12] = 1     # status
        br_data[i, 13] = -360; br_data[i, 14] = 360
    end
    jpc.branch = ComponentMatrix{BranchSchema, T}(br_data)

    # Substation gen at bus 1 (INDEX is column 1, GEN_BUS is column 2)
    gen_data = zeros(T, 1, ncols(GenSchema))
    gen_data[1, 1] = 1      # INDEX
    gen_data[1, 2] = 1      # GEN_BUS
    gen_data[1, 7] = 1.0    # VG
    gen_data[1, 8] = 10     # MBASE
    gen_data[1, 9] = 1      # STATUS
    gen_data[1, 10] = 10    # PMAX
    gen_data[1, 5] = 10     # QMAX
    gen_data[1, 6] = -10    # QMIN
    jpc.gen = ComponentMatrix{GenSchema, T}(gen_data)

    return jpc
end
