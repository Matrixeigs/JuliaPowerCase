# ═══════════════════════════════════════════════════════════════════════════════
# Utils Compatibility Types
# Types compatible with Utils/src/Types.jl for validation and interoperability
# ═══════════════════════════════════════════════════════════════════════════════

"""
    JPC

Matrix-based power system case structure compatible with Utils module.
Each field is a 2D array where rows are components and columns are attributes.
Column indices are defined in the corresponding idx_*.jl files.

# Fields
- `version`: Version string
- `baseMVA`: Base MVA for per-unit conversion
- `success`: Power flow convergence status
- `iterationsAC`: AC power flow iteration count
- `iterationsDC`: DC power flow iteration count
- `busAC`: AC bus matrix (n_bus × N_BUS_ATTR)
- `genAC`: Generator matrix (n_gen × N_GEN_ATTR)
- `branchAC`: Branch matrix (n_branch × N_BRANCH_ATTR)
- ...and more component matrices

# Example
```julia
jpc = JPC()
jpc.busAC = zeros(10, 22)  # 10 buses with 22 attributes
```
"""
mutable struct JPC
    version::String
    baseMVA::Float64
    success::Bool
    iterationsAC::Int
    iterationsDC::Int
    
    # AC Network Components
    busAC::Array{Float64,2}         # Bus data (n_bus × N_BUS_ATTR)
    genAC::Array{Float64,2}         # Generator data (n_gen × N_GEN_ATTR)
    branchAC::Array{Float64,2}      # Branch data (n_branch × N_BRANCH_ATTR)
    loadAC::Array{Float64,2}        # Load data (n_load × N_LOAD_ATTR)
    loadAC_flex::Array{Float64,2}   # Flexible load data
    loadAC_asymm::Array{Float64,2}  # Asymmetric load data
    branch3ph::Array{Float64,2}     # Three-phase branch data
    
    # DC Network Components
    busDC::Array{Float64,2}         # DC bus data
    branchDC::Array{Float64,2}      # DC branch data
    genDC::Array{Float64,2}         # DC generator data
    loadDC::Array{Float64,2}        # DC load data
    
    # Distributed Energy Resources
    sgenAC::Array{Float64,2}        # Static generator data
    storageetap::Array{Float64,2}   # ETAP storage data
    storage::Array{Float64,2}       # Energy storage data
    sgenDC::Array{Float64,2}        # DC static generator data
    pv::Array{Float64,2}            # PV array data
    pv_acsystem::Array{Float64,2}   # AC PV system data
    
    # Special Components
    converter::Array{Float64,2}     # AC/DC converter data
    batteryAC::Array{Float64,2}     # AC battery storage
    batteryDC::Array{Float64,2}     # DC battery storage
    energyrouterCore::Array{Float64,2}      # Energy router core
    energyrouterConverter::Array{Float64,2} # Energy router converter
    ext_grid::Array{Float64,2}      # External grid data
    hvcb::Array{Float64,2}          # High voltage circuit breaker
    microgrid::Array{Float64,2}     # Microgrid data

    # ID-Name mapping
    bus_name_to_id::Dict{String, Int}
    
    # Constructor with default empty arrays
    function JPC(version::String = "2.0", baseMVA::Float64 = 100.0, 
                 success::Bool = false, iterationsAC::Int = 0, iterationsDC::Int = 0)
        Base.depwarn(
            "JPC is deprecated and will be removed in v0.3. " *
            "Use PowerCaseData{AC,Float64} instead. " *
            "See documentation for migration guide.",
            :JPC
        )
        new(version, baseMVA, success, iterationsAC, iterationsDC,
            Array{Float64}(undef, 0, 22),  # busAC
            Array{Float64}(undef, 0, 32),  # genAC
            Array{Float64}(undef, 0, 37),  # branchAC
            Array{Float64}(undef, 0, 8),   # loadAC
            Array{Float64}(undef, 0, 25),  # loadAC_flex
            Array{Float64}(undef, 0, 12),  # loadAC_asymm
            Array{Float64}(undef, 0, 30),  # branch3ph
            Array{Float64}(undef, 0, 23),  # busDC
            Array{Float64}(undef, 0, 28),  # branchDC
            Array{Float64}(undef, 0, 32),  # genDC
            Array{Float64}(undef, 0, 8),   # loadDC
            Array{Float64}(undef, 0, 3),   # sgenAC
            Array{Float64}(undef, 0, 15),  # storageetap
            Array{Float64}(undef, 0, 15),  # storage
            Array{Float64}(undef, 0, 3),   # sgenDC
            Array{Float64}(undef, 0, 9),   # pv
            Array{Float64}(undef, 0, 15),  # pv_acsystem
            Array{Float64}(undef, 0, 18),  # converter
            Array{Float64}(undef, 0, 12),  # batteryAC
            Array{Float64}(undef, 0, 11),  # batteryDC
            Array{Float64}(undef, 0, 7),   # energyrouterCore
            Array{Float64}(undef, 0, 15),  # energyrouterConverter
            Array{Float64}(undef, 0, 13),  # ext_grid
            Array{Float64}(undef, 0, 5),   # hvcb
            Array{Float64}(undef, 0, 5),   # microgrid
            Dict{String, Int}()            # bus_name_to_id
        )
    end
end

# Dictionary-like access for JPC
function Base.getindex(jpc::JPC, key::String)
    if key == "version" return jpc.version
    elseif key == "baseMVA" return jpc.baseMVA
    elseif key == "success" return jpc.success
    elseif key == "iterationsAC" return jpc.iterationsAC
    elseif key == "iterationsDC" return jpc.iterationsDC
    elseif key == "busAC" return jpc.busAC
    elseif key == "genAC" return jpc.genAC
    elseif key == "branchAC" return jpc.branchAC
    elseif key == "loadAC" return jpc.loadAC
    elseif key == "loadAC_flex" return jpc.loadAC_flex
    elseif key == "loadAC_asymm" return jpc.loadAC_asymm
    elseif key == "branch3ph" return jpc.branch3ph
    elseif key == "busDC" return jpc.busDC
    elseif key == "branchDC" return jpc.branchDC
    elseif key == "genDC" return jpc.genDC
    elseif key == "loadDC" return jpc.loadDC
    elseif key == "sgenAC" return jpc.sgenAC
    elseif key == "storageetap" return jpc.storageetap
    elseif key == "storage" return jpc.storage
    elseif key == "sgenDC" return jpc.sgenDC
    elseif key == "pv" return jpc.pv
    elseif key == "pv_acsystem" return jpc.pv_acsystem
    elseif key == "converter" return jpc.converter
    elseif key == "batteryAC" return jpc.batteryAC
    elseif key == "batteryDC" return jpc.batteryDC
    elseif key == "energyrouterCore" return jpc.energyrouterCore
    elseif key == "energyrouterConverter" return jpc.energyrouterConverter
    elseif key == "ext_grid" return jpc.ext_grid
    elseif key == "hvcb" return jpc.hvcb
    elseif key == "microgrid" return jpc.microgrid
    elseif key == "bus_name_to_id" return jpc.bus_name_to_id
    else error("Key '$key' does not exist in JPC struct")
    end
end

function Base.setindex!(jpc::JPC, value, key::String)
    if key == "version" jpc.version = value
    elseif key == "baseMVA" jpc.baseMVA = value
    elseif key == "success" jpc.success = value
    elseif key == "iterationsAC" jpc.iterationsAC = value
    elseif key == "iterationsDC" jpc.iterationsDC = value
    elseif key == "busAC" jpc.busAC = value
    elseif key == "genAC" jpc.genAC = value
    elseif key == "branchAC" jpc.branchAC = value
    elseif key == "loadAC" jpc.loadAC = value
    elseif key == "loadAC_flex" jpc.loadAC_flex = value
    elseif key == "loadAC_asymm" jpc.loadAC_asymm = value
    elseif key == "branch3ph" jpc.branch3ph = value
    elseif key == "busDC" jpc.busDC = value
    elseif key == "branchDC" jpc.branchDC = value
    elseif key == "genDC" jpc.genDC = value
    elseif key == "loadDC" jpc.loadDC = value
    elseif key == "sgenAC" jpc.sgenAC = value
    elseif key == "storageetap" jpc.storageetap = value
    elseif key == "storage" jpc.storage = value
    elseif key == "sgenDC" jpc.sgenDC = value
    elseif key == "pv" jpc.pv = value
    elseif key == "pv_acsystem" jpc.pv_acsystem = value
    elseif key == "converter" jpc.converter = value
    elseif key == "batteryAC" jpc.batteryAC = value
    elseif key == "batteryDC" jpc.batteryDC = value
    elseif key == "energyrouterCore" jpc.energyrouterCore = value
    elseif key == "energyrouterConverter" jpc.energyrouterConverter = value
    elseif key == "ext_grid" jpc.ext_grid = value
    elseif key == "hvcb" jpc.hvcb = value
    elseif key == "microgrid" jpc.microgrid = value
    else error("Key '$key' does not exist in JPC struct")
    end
end


"""
    JPC_3ph

Three-phase matrix-based power system case for unbalanced power flow.

# Fields
- Sequence components (0, 1, 2) for bus, branch, load, gen
- DC network components
- Three-phase power flow results
"""
mutable struct JPC_3ph
    version::String
    baseMVA::Float32
    basef::Float32
    mode::String
    success::Bool
    iterations::Int

    # AC Network Components - Sequence matrices
    busAC_0::Array{Float64,2}
    busAC_1::Array{Float64,2}
    busAC_2::Array{Float64,2}
    branchAC_0::Array{Float64,2}
    branchAC_1::Array{Float64,2}
    branchAC_2::Array{Float64,2}
    loadAC_0::Array{Float64,2}
    loadAC_1::Array{Float64,2}
    loadAC_2::Array{Float64,2}
    genAC_0::Array{Float64,2}
    genAC_1::Array{Float64,2}
    genAC_2::Array{Float64,2}
    storageAC::Array{Float64,2}

    # DC Network Components
    busDC::Array{Float64,2}
    branchDC::Array{Float64,2}
    loadDC::Array{Float64,2}
    genDC::Array{Float64,2}
    storageDC::Array{Float64,2}

    # Special Components
    ext_grid::Array{Float64,2}
    switche::Array{Float64,2}

    # Three-phase power flow results
    res_bus_3ph::Array{Float64,2}
    res_loadsAC_3ph::Array{Float64,2}
    res_ext_grid_3ph::Array{Float64,2}

    # Lookup dictionaries
    bus_name_to_id::Dict{String, Int}
    zone_to_id::Dict{String, Int}
    area_to_id::Dict{String, Int}

    # Constructor
    function JPC_3ph(version::String = "2.0", baseMVA::Float32 = 100.0f0, 
                     basef::Float32 = 50.0f0, mode::String = "etap",
                     success::Bool = false, iterations::Int = 0)
        Base.depwarn(
            "JPC_3ph is deprecated and will be removed in v0.3. " *
            "Use PowerCaseData with sequence components instead. " *
            "See documentation for migration guide.",
            :JPC_3ph
        )
        return new(
            version, baseMVA, basef, mode, success, iterations,
            # Sequence matrices
            Array{Float64}(undef, 0, 22),  # busAC_0
            Array{Float64}(undef, 0, 22),  # busAC_1
            Array{Float64}(undef, 0, 22),  # busAC_2
            Array{Float64}(undef, 0, 28),  # branchAC_0
            Array{Float64}(undef, 0, 28),  # branchAC_1
            Array{Float64}(undef, 0, 28),  # branchAC_2
            Array{Float64}(undef, 0, 8),   # loadAC_0
            Array{Float64}(undef, 0, 8),   # loadAC_1
            Array{Float64}(undef, 0, 8),   # loadAC_2
            Array{Float64}(undef, 0, 32),  # genAC_0
            Array{Float64}(undef, 0, 32),  # genAC_1
            Array{Float64}(undef, 0, 32),  # genAC_2
            Array{Float64}(undef, 0, 15),  # storageAC
            # DC components
            Array{Float64}(undef, 0, 21),  # busDC
            Array{Float64}(undef, 0, 28),  # branchDC
            Array{Float64}(undef, 0, 8),   # loadDC
            Array{Float64}(undef, 0, 32),  # genDC
            Array{Float64}(undef, 0, 15),  # storageDC
            # Special
            Array{Float64}(undef, 0, 13),  # ext_grid
            Array{Float64}(undef, 0, 5),   # switche
            # Results
            Array{Float64}(undef, 0, 15),  # res_bus_3ph
            Array{Float64}(undef, 0, 18),  # res_loadsAC_3ph
            Array{Float64}(undef, 0, 13),  # res_ext_grid_3ph
            # Lookup
            Dict{String, Int}(),
            Dict{String, Int}(),
            Dict{String, Int}()
        )
    end
end

# Dictionary-like access for JPC_3ph
function Base.getindex(jpc::JPC_3ph, key::String)
    if key == "version" return jpc.version
    elseif key == "baseMVA" return jpc.baseMVA
    elseif key == "basef" return jpc.basef
    elseif key == "mode" return jpc.mode
    elseif key == "success" return jpc.success
    elseif key == "iterations" return jpc.iterations
    elseif key == "busAC_0" return jpc.busAC_0
    elseif key == "busAC_1" return jpc.busAC_1
    elseif key == "busAC_2" return jpc.busAC_2
    elseif key == "branchAC_0" return jpc.branchAC_0
    elseif key == "branchAC_1" return jpc.branchAC_1
    elseif key == "branchAC_2" return jpc.branchAC_2
    elseif key == "loadAC_0" return jpc.loadAC_0
    elseif key == "loadAC_1" return jpc.loadAC_1
    elseif key == "loadAC_2" return jpc.loadAC_2
    elseif key == "genAC_0" return jpc.genAC_0
    elseif key == "genAC_1" return jpc.genAC_1
    elseif key == "genAC_2" return jpc.genAC_2
    elseif key == "storageAC" return jpc.storageAC
    elseif key == "busDC" return jpc.busDC
    elseif key == "branchDC" return jpc.branchDC
    elseif key == "loadDC" return jpc.loadDC
    elseif key == "genDC" return jpc.genDC
    elseif key == "storageDC" return jpc.storageDC
    elseif key == "ext_grid" return jpc.ext_grid
    elseif key == "switche" return jpc.switche
    elseif key == "res_bus_3ph" return jpc.res_bus_3ph
    elseif key == "res_loadsAC_3ph" return jpc.res_loadsAC_3ph
    elseif key == "res_ext_grid_3ph" return jpc.res_ext_grid_3ph
    elseif key == "bus_name_to_id" return jpc.bus_name_to_id
    elseif key == "zone_to_id" return jpc.zone_to_id
    elseif key == "area_to_id" return jpc.area_to_id
    else error("Key '$key' does not exist in JPC_3ph struct")
    end
end

function Base.setindex!(jpc::JPC_3ph, value, key::String)
    if key == "version" jpc.version = value
    elseif key == "baseMVA" jpc.baseMVA = value
    elseif key == "basef" jpc.basef = value
    elseif key == "mode" jpc.mode = value
    elseif key == "success" jpc.success = value
    elseif key == "iterations" jpc.iterations = value
    elseif key == "busAC_0" jpc.busAC_0 = value
    elseif key == "busAC_1" jpc.busAC_1 = value
    elseif key == "busAC_2" jpc.busAC_2 = value
    elseif key == "branchAC_0" jpc.branchAC_0 = value
    elseif key == "branchAC_1" jpc.branchAC_1 = value
    elseif key == "branchAC_2" jpc.branchAC_2 = value
    elseif key == "loadAC_0" jpc.loadAC_0 = value
    elseif key == "loadAC_1" jpc.loadAC_1 = value
    elseif key == "loadAC_2" jpc.loadAC_2 = value
    elseif key == "genAC_0" jpc.genAC_0 = value
    elseif key == "genAC_1" jpc.genAC_1 = value
    elseif key == "genAC_2" jpc.genAC_2 = value
    elseif key == "storageAC" jpc.storageAC = value
    elseif key == "busDC" jpc.busDC = value
    elseif key == "branchDC" jpc.branchDC = value
    elseif key == "loadDC" jpc.loadDC = value
    elseif key == "genDC" jpc.genDC = value
    elseif key == "storageDC" jpc.storageDC = value
    elseif key == "ext_grid" jpc.ext_grid = value
    elseif key == "switche" jpc.switche = value
    elseif key == "res_bus_3ph" jpc.res_bus_3ph = value
    elseif key == "res_loadsAC_3ph" jpc.res_loadsAC_3ph = value
    elseif key == "res_ext_grid_3ph" jpc.res_ext_grid_3ph = value
    else error("Key '$key' does not exist in JPC_3ph struct")
    end
end


"""
    JPC_sc

Short-circuit calculation matrix-based structure.
Contains network data and short-circuit results.
"""
mutable struct JPC_sc 
    version::String
    baseMVA::Float32
    basef::Float32
    mode::String

    # Matrix data
    bus::Array{Float64,2}
    sgen::Array{Float64,2}
    gen::Array{Float64,2}
    branch::Array{Float64,2}
    transformer::Array{Float64,2}
    asynchronous_motor::Array{Float64,2}
    load::Array{Float64,2}
    ext_grids::Array{Float64,2}

    # Results
    res_sc::Array{Float64,2}
    impedance_matrix::Array{Complex{Float64},2}

    # Dictionary mapping
    bus_name_to_id::Dict{String, Int}
    zone_to_id::Dict{String, Int}
    area_to_id::Dict{String, Int}

    # Constructor
    function JPC_sc(version::String = "2.0", baseMVA::Float32 = 100.0f0,
                    basef::Float32 = 50.0f0, mode::String = "sc")
        Base.depwarn(
            "JPC_sc is deprecated and will be removed in v0.3. " *
            "Use PowerCaseData with short-circuit fields instead. " *
            "See documentation for migration guide.",
            :JPC_sc
        )
        return new(
            version, baseMVA, basef, mode,
            Array{Float64}(undef, 0, 22),  # bus
            Array{Float64}(undef, 0, 32),  # sgen
            Array{Float64}(undef, 0, 37),  # gen
            Array{Float64}(undef, 0, 28),  # branch
            Array{Float64}(undef, 0, 18),  # transformer
            Array{Float64}(undef, 0, 20),  # asynchronous_motor
            Array{Float64}(undef, 0, 20),  # load
            Array{Float64}(undef, 0, 13),  # ext_grids
            Array{Float64}(undef, 0, 5),   # res_sc
            Array{Complex{Float64}}(undef, 0, 0), # impedance_matrix
            Dict{String, Int}(),
            Dict{String, Int}(),
            Dict{String, Int}()
        )
    end
end

# Dictionary-like access for JPC_sc
function Base.getindex(jpc::JPC_sc, key::String)
    if key == "version" return jpc.version
    elseif key == "baseMVA" return jpc.baseMVA
    elseif key == "basef" return jpc.basef
    elseif key == "mode" return jpc.mode
    elseif key == "bus" return jpc.bus
    elseif key == "sgen" return jpc.sgen
    elseif key == "gen" return jpc.gen
    elseif key == "branch" return jpc.branch
    elseif key == "transformer" return jpc.transformer
    elseif key == "asynchronous_motor" return jpc.asynchronous_motor
    elseif key == "load" return jpc.load
    elseif key == "ext_grids" return jpc.ext_grids
    elseif key == "res_sc" return jpc.res_sc
    elseif key == "impedance_matrix" return jpc.impedance_matrix
    elseif key == "bus_name_to_id" return jpc.bus_name_to_id
    elseif key == "zone_to_id" return jpc.zone_to_id
    elseif key == "area_to_id" return jpc.area_to_id
    else error("Key '$key' does not exist in JPC_sc struct")
    end
end

function Base.setindex!(jpc::JPC_sc, value, key::String)
    if key == "version" jpc.version = value
    elseif key == "baseMVA" jpc.baseMVA = value
    elseif key == "basef" jpc.basef = value
    elseif key == "mode" jpc.mode = value
    elseif key == "bus" jpc.bus = value
    elseif key == "sgen" jpc.sgen = value
    elseif key == "gen" jpc.gen = value
    elseif key == "branch" jpc.branch = value
    elseif key == "transformer" jpc.transformer = value
    elseif key == "asynchronous_motor" jpc.asynchronous_motor = value
    elseif key == "load" jpc.load = value
    elseif key == "ext_grids" jpc.ext_grids = value
    elseif key == "res_sc" jpc.res_sc = value
    elseif key == "impedance_matrix" jpc.impedance_matrix = value
    elseif key == "bus_name_to_id" jpc.bus_name_to_id = value
    elseif key == "zone_to_id" jpc.zone_to_id = value
    elseif key == "area_to_id" jpc.area_to_id = value
    else error("Key '$key' does not exist in JPC_sc struct")
    end
end


"""
    Fault_sc

Short-circuit fault definition structure.
Defines fault type, location, and calculation parameters.

# Fields
- `fault_type`: :three_phase, :single_line_ground, :line_line, :line_line_ground
- `fault_bus`: Bus number where fault occurs
- `fault_impedance`: Fault impedance (Complex)
- `calculation_type`: :max (maximum), :min (minimum)
- `breaking_time`: Breaker operation time (s)
- `topology`: :radial, :meshed
- `kappa_method`: Peak current calculation method (:C, :B, :method_c)
"""
mutable struct Fault_sc
    version::String
    baseMVA::Float32
    basef::Float32
    mode::String
    fault_type::Symbol
    fault_bus::Int
    fault_impedance::Complex{Float64}
    calculation_type::Symbol
    breaking_time::Float64
    topology::Symbol
    kappa_method::Symbol

    function Fault_sc(
        version::String = "2.0",
        baseMVA::Float32 = 100.0f0,
        basef::Float32 = 50.0f0,
        mode::String = "sc",
        fault_type::Symbol = :three_phase,
        fault_bus::Int = 1,
        fault_impedance::Complex{Float64} = 0.0 + 0.0im,
        calculation_type::Symbol = :max,
        breaking_time::Float64 = 0.0,
        topology::Symbol = :radial,
        kappa_method::Symbol = :C
    )
        return new(version, baseMVA, basef, mode, fault_type, fault_bus,
                   fault_impedance, calculation_type, breaking_time, 
                   topology, kappa_method)
    end
end


"""
    JPC_tp

Topology analysis matrix-based structure.
Simplified structure for network topology operations.
"""
mutable struct JPC_tp
    version::String
    baseMVA::Float64
    
    # AC Network Components
    busAC::Array{Float64,2}
    genAC::Array{Float64,2}
    branchAC::Array{Float64,2}
    loadAC::Array{Float64,2}
    
    # DC Network Components
    busDC::Array{Float64,2}
    branchDC::Array{Float64,2}
    genDC::Array{Float64,2}
    loadDC::Array{Float64,2}
    
    # Distributed Energy Resources
    sgenAC::Array{Float64,2}
    storageetap::Array{Float64,2}
    storage::Array{Float64,2}
    sgenDC::Array{Float64,2}
    pv::Array{Float64,2}
    pv_acsystem::Array{Float64,2}
    
    # Special Components
    converter::Array{Float64,2}
    ext_grid::Array{Float64,2}
    hvcb::Array{Float64,2}
    microgrid::Array{Float64,2}

    # Constructor
    function JPC_tp(version::String = "2.0", baseMVA::Float64 = 100.0)
        Base.depwarn(
            "JPC_tp is deprecated and will be removed in v0.3. " *
            "Use HybridPowerCaseData instead. " *
            "See documentation for migration guide.",
            :JPC_tp
        )
        new(version, baseMVA,
            Array{Float64}(undef, 0, 22),  # busAC
            Array{Float64}(undef, 0, 32),  # genAC
            Array{Float64}(undef, 0, 28),  # branchAC
            Array{Float64}(undef, 0, 8),   # loadAC
            Array{Float64}(undef, 0, 21),  # busDC
            Array{Float64}(undef, 0, 28),  # branchDC
            Array{Float64}(undef, 0, 32),  # genDC
            Array{Float64}(undef, 0, 8),   # loadDC
            Array{Float64}(undef, 0, 3),   # sgenAC
            Array{Float64}(undef, 0, 15),  # storageetap
            Array{Float64}(undef, 0, 15),  # storage
            Array{Float64}(undef, 0, 3),   # sgenDC
            Array{Float64}(undef, 0, 9),   # pv
            Array{Float64}(undef, 0, 15),  # pv_acsystem
            Array{Float64}(undef, 0, 18),  # converter
            Array{Float64}(undef, 0, 13),  # ext_grid
            Array{Float64}(undef, 0, 5),   # hvcb
            Array{Float64}(undef, 0, 5)    # microgrid
        )
    end
end

# Dictionary-like access for JPC_tp
function Base.getindex(jpc::JPC_tp, key::String)
    if key == "version" return jpc.version
    elseif key == "baseMVA" return jpc.baseMVA
    elseif key == "busAC" return jpc.busAC
    elseif key == "genAC" return jpc.genAC
    elseif key == "branchAC" return jpc.branchAC
    elseif key == "loadAC" return jpc.loadAC
    elseif key == "busDC" return jpc.busDC
    elseif key == "branchDC" return jpc.branchDC
    elseif key == "genDC" return jpc.genDC
    elseif key == "loadDC" return jpc.loadDC
    elseif key == "sgenAC" return jpc.sgenAC
    elseif key == "storageetap" return jpc.storageetap
    elseif key == "storage" return jpc.storage
    elseif key == "sgenDC" return jpc.sgenDC
    elseif key == "pv" return jpc.pv
    elseif key == "pv_acsystem" return jpc.pv_acsystem
    elseif key == "converter" return jpc.converter
    elseif key == "ext_grid" return jpc.ext_grid
    elseif key == "hvcb" return jpc.hvcb
    elseif key == "microgrid" return jpc.microgrid
    else error("Key '$key' does not exist in JPC_tp struct")
    end
end

function Base.setindex!(jpc::JPC_tp, value, key::String)
    if key == "version" jpc.version = value
    elseif key == "baseMVA" jpc.baseMVA = value
    elseif key == "busAC" jpc.busAC = value
    elseif key == "genAC" jpc.genAC = value
    elseif key == "branchAC" jpc.branchAC = value
    elseif key == "loadAC" jpc.loadAC = value
    elseif key == "busDC" jpc.busDC = value
    elseif key == "branchDC" jpc.branchDC = value
    elseif key == "genDC" jpc.genDC = value
    elseif key == "loadDC" jpc.loadDC = value
    elseif key == "sgenAC" jpc.sgenAC = value
    elseif key == "storageetap" jpc.storageetap = value
    elseif key == "storage" jpc.storage = value
    elseif key == "sgenDC" jpc.sgenDC = value
    elseif key == "pv" jpc.pv = value
    elseif key == "pv_acsystem" jpc.pv_acsystem = value
    elseif key == "converter" jpc.converter = value
    elseif key == "ext_grid" jpc.ext_grid = value
    elseif key == "hvcb" jpc.hvcb = value
    elseif key == "microgrid" jpc.microgrid = value
    else error("Key '$key' does not exist in JPC_tp struct")
    end
end


# ═══════════════════════════════════════════════════════════════════════════════
# haskey implementations
# ═══════════════════════════════════════════════════════════════════════════════

const JPC_KEYS = Set([
    "version", "baseMVA", "success", "iterationsAC", "iterationsDC",
    "busAC", "genAC", "branchAC", "loadAC", "loadAC_flex", "loadAC_asymm", "branch3ph",
    "busDC", "branchDC", "genDC", "loadDC",
    "sgenAC", "storageetap", "storage", "sgenDC", "pv", "pv_acsystem",
    "converter", "batteryAC", "batteryDC", "energyrouterCore", "energyrouterConverter",
    "ext_grid", "hvcb", "microgrid", "bus_name_to_id"
])

Base.haskey(jpc::JPC, key::String) = key in JPC_KEYS

const JPC_3PH_KEYS = Set([
    "version", "baseMVA", "basef", "mode", "success", "iterations",
    "busAC_0", "busAC_1", "busAC_2", "branchAC_0", "branchAC_1", "branchAC_2",
    "loadAC_0", "loadAC_1", "loadAC_2", "genAC_0", "genAC_1", "genAC_2", "storageAC",
    "busDC", "branchDC", "loadDC", "genDC", "storageDC",
    "ext_grid", "switche", "res_bus_3ph", "res_loadsAC_3ph", "res_ext_grid_3ph",
    "bus_name_to_id", "zone_to_id", "area_to_id"
])

Base.haskey(jpc::JPC_3ph, key::String) = key in JPC_3PH_KEYS

const JPC_SC_KEYS = Set([
    "version", "baseMVA", "basef", "mode",
    "bus", "sgen", "gen", "branch", "transformer", "asynchronous_motor", "load", "ext_grids",
    "res_sc", "impedance_matrix", "bus_name_to_id", "zone_to_id", "area_to_id"
])

Base.haskey(jpc::JPC_sc, key::String) = key in JPC_SC_KEYS

const JPC_TP_KEYS = Set([
    "version", "baseMVA",
    "busAC", "genAC", "branchAC", "loadAC",
    "busDC", "branchDC", "genDC", "loadDC",
    "sgenAC", "storageetap", "storage", "sgenDC", "pv", "pv_acsystem",
    "converter", "ext_grid", "hvcb", "microgrid"
])

Base.haskey(jpc::JPC_tp, key::String) = key in JPC_TP_KEYS


# ═══════════════════════════════════════════════════════════════════════════════
# Pretty printing
# ═══════════════════════════════════════════════════════════════════════════════

function Base.show(io::IO, jpc::JPC)
    nbus = size(jpc.busAC, 1)
    nbranch = size(jpc.branchAC, 1)
    ngen = size(jpc.genAC, 1)
    print(io, "JPC($(nbus) buses, $(nbranch) branches, $(ngen) gens, success=$(jpc.success))")
end

function Base.show(io::IO, jpc::JPC_3ph)
    nbus = size(jpc.busAC_1, 1)
    print(io, "JPC_3ph($(nbus) buses, mode=$(jpc.mode), success=$(jpc.success))")
end

function Base.show(io::IO, jpc::JPC_sc)
    nbus = size(jpc.bus, 1)
    print(io, "JPC_sc($(nbus) buses, mode=$(jpc.mode))")
end

function Base.show(io::IO, fault::Fault_sc)
    print(io, "Fault_sc(bus=$(fault.fault_bus), type=$(fault.fault_type), calc=$(fault.calculation_type))")
end

function Base.show(io::IO, jpc::JPC_tp)
    nbus = size(jpc.busAC, 1)
    nbranch = size(jpc.branchAC, 1)
    print(io, "JPC_tp($(nbus) buses, $(nbranch) branches)")
end
