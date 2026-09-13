%[text] # Optimizer: 1D Hydraulic Simulation
%%
%[text] ## Testing Harness
%[text] Filling up all required variables to test basic functionality. Can also be used to compare CFD results after extracting the required geometrical values from the CFturbo file. 
%[text] ### Test 1D Hydraulic Solver with CoolProp & Blade Angle Calculation
clear; clc; tic();
%[text] Fluid & Thermodynamic State (Subcooled LOX Example)
ParSim.fluid.name = 'Oxygen';        % CoolProp fluid string
ParSim.fluid.temperature_K = 85.0;   % Subcooled LOX Temp (K)
ParSim.fluid.pressure_Pa = 5e5;      % Suction Pressure (Pa)
%[text] Operating Parameters
ParSim.operating.Q_in = 250.0;            % Flow rate [L/min]
ParSim.operating.N_rpm = 28000;           % Shaft speed [RPM]
ParSim.operating.dp_target_bar = 75.0;    % Pressure rise target [bar]
%[text] Impeller & Volute Geometry (mm)
ParSim.pump.d2 = 78.0;          % Impeller outlet diameter [mm]
ParSim.pump.b2 = 4.6;           % Outlet blade width [mm]

ParSim.pump.Imp_inDia = 33.0;   % Impeller inlet diameter [mm]
ParSim.pump.b1 = 10.0;          % Inlet blade width [mm]

ParSim.pump.Z_LA = 8;           % Blade count [-]

ParSim.pump.d3_i = 80;          % Volute inlet diameter [mm]
ParSim.pump.b3_i = 13;          % Volute width [mm]

ParSim.pump.D_hub = 20.0;       % Hub diameter [mm]
ParSim.pump.deye = 33.0;        % Impeller eye diameter [mm]

ParSim.pump.alphaTH = 2.0;      % Cut-water throat angle [deg]
ParSim.pump.L_throat = 100.0;   % Throat length [mm]
%[text] Inducer Geometry
ParSim.inducer.D_tip = ParSim.pump.deye;      % mm, Inducer OD matches impeller eye
ParSim.inducer.D_hub = ParSim.pump.D_hub;     % mm, Inducer ID matches shaft hub
ParSim.inducer.beta_tip = 12.0;               % deg, Inducer tip blade angle 
ParSim.inducer.eta_ind = 0.70;                % Initial inducer hydraulic efficiency 
%[text] Cavitation / NPSH Parameters
ParSim.operating.p_suction_abs = 5e5;  % Absolute suction pressure [Pa]
ParSim.operating.p_vapor = 1.2e5;      % Absolute vapor pressure [Pa]
ParSim.operating.NPSH_required = 4.5;  % NPSHR [m]             
%[text] Constants & Loss Parameters
%[text] *Notes:* 
%[text] - *Many of these are extracted from the example rocket turbopump CFturbo file and serve as a good jumping off point.*
%[text] - *The discharge coefficient was determined by doing simulations on the example CFturbo file at different points and seeing how it varies depending on RPM; thus, the discharge coefficient is mapped to the RPM operating point value.*  \
ParSim.constants.eta_h_guess = 0.50;             % Initial hydraulic efficiency guess
ParSim.constants.inlet_prewhirl = 0.0;           % Pre-whirl velocity [m/s]
ParSim.constants.inlet_span = 0.5;               % Mid-span calculation point
ParSim.constants.incidence_deg = 0.0;            % Zero-incidence design
ParSim.constants.beta2_bounds_deg = [15 70];     % Realistic range for outlet blade angle
ParSim.constants.y_gap = 0.50;                   % Tip gap clearance [mm]
ParSim.constants.yc_i = 0.50;                    % Volute side clearance [mm]
ParSim.constants.e1 = 1.5;                       % Blade thickness [mm]
ParSim.constants.cdl = 0.00012;                  % Leakage discharge coefficient (NEED TO MAP THIS BASED ON RPM)
ParSim.constants.ceye = 1.00;                    % Eye entry coefficient
ParSim.constants.k_volute_i = 1.0e-4;            % Surface roughness in volute [m]
ParSim.constants.k_impeller_i = 1.0e-4;          % Surface roughness in impeller [m]
ParSim.constants.NPoints = 80;                   % Discretization resolution
ParSim.constants.slipLossMulti = 1.0;
%[text] #### Run calculations
%[text] 1\. Run 1D Axial Inducer Stage Analytical Model
OutInducer = InducerSolver_1D(ParSim);

% Boost suction pressure entering the centrifugal stage.
ParSim.operating.p_suction_abs = ParSim.operating.p_suction_abs + OutInducer.dp_inducer_Pa;

% Reduce the suction pressure entering the centrifugal stage.
ParSim.operating.dp_target_bar = ParSim.operating.dp_target_bar - OutInducer.dp_inducer_bar;
%[text] 2\. Calculate Dependent Blade Angles
AngleOut = calculate_pump_blade_angles(ParSim);
ParSim.pump.Beta_1 = AngleOut.Beta1_deg;
ParSim.pump.Beta_2 = AngleOut.Beta2_deg;
%[text] 3\. Run 1D Hydraulic Performance Solver
OutPump = HydSolver_1D(ParSim);
runtime = toc();
%[text] 4\. Display Key Outputs
disp('==================== PUMP METRICS ===================='); %[output:06c7bdb7]
fprintf('Pressure Rise       : %.2f bar\n', OutPump.pressure + OutInducer.dp_inducer_bar); %[output:75f9be99]
fprintf('Shaft Torque        : %.2f Nm\n', OutPump.torque); %[output:060a8d27]
fprintf('Hydraulic Efficiency: %.2f %\n', OutPump.efficiency * 100); %[output:8b29d7ad]
fprintf('Axial Thrust Force  : %.2f N\n', OutPump.F_axial); %[output:8c3bde89]

disp('================ CALCULATED ANGLES ==================='); %[output:71fcca51]
fprintf('Inlet Blade Angle (Beta 1) : %.2f deg\n', OutPump.calculated_angles.Beta1_deg); %[output:0e1532fb]
fprintf('Outlet Blade Angle (Beta 2): %.2f deg\n', OutPump.calculated_angles.Beta2_deg); %[output:129fe68c]
fprintf('Flow Deviation Angle       : %.2f deg\n', AngleOut.deviation_deg); %[output:6ea0a3f2]

disp('============== INDUCER STAGE RESULTS ================='); %[output:934e023a]
fprintf('Inducer Axial Velocity (Cz): %.2f m/s\n', OutInducer.c_z); %[output:2e157e9b]
fprintf('Inducer Tip Speed (Utip)   : %.2f m/s\n', OutInducer.u_tip); %[output:45809bf1]
fprintf('Inducer Pressure Rise      : %.2f bar\n\n', OutInducer.dp_inducer_bar); %[output:4fa87db3]

disp('============== NASA SP-8109 SCREENING ================'); %[output:04fa2479]
fprintf('Non-Dim Specific Speed (Ns): %.3f\n', AngleOut.Ns_nondim); %[output:8a18d20f]
fprintf('Non-Dim Specific Dia   (Ds): %.3f (Optimum: %.3f)\n', AngleOut.Ds_nondim, AngleOut.Ds_opt); %[output:8be8a566]
fprintf('Ds Ratio (Ds / Ds_opt)    : %.2f\n', AngleOut.Ds_ratio); %[output:4a7bb452]
if AngleOut.NASA_SP8109_viable %[output:group:548c7dff]
    disp('NASA SP-8109 Viability      : PASS (Geometry sits near Cordier optimum)'); %[output:53c7ced2]
else
    disp('NASA SP-8109 Viability      : WARNING (Geometry deviates significantly from Cordier optimum)');
end %[output:group:548c7dff]

disp('================ CAVITATION CHECK ===================='); %[output:87640fc7]
fprintf('NPSH Available : %.2f m\n', OutPump.cavitation.NPSH_available_m); %[output:294ccd96]
fprintf('NPSH Required  : %.2f m\n', OutPump.cavitation.NPSH_required_m); %[output:0a179b13]
fprintf('NPSH Margin    : %.2f m\n', OutPump.cavitation.NPSH_margin_m); %[output:7d2027c8]
fprintf('Cavitation Status: %s\n', OutPump.cavitation.status); %[output:91bce2b8]

disp('=================== RUN TIME ========================='); %[output:814b7237]
fprintf('Execution Time : %.4f seconds\n', runtime); %[output:8b66469f]
%%
%[text] ## Optimizer
%[text] In the foundational stage of this Multidisciplinary Design Optimization (MDO) pipeline, a 1D mean-line analytical solver was developed using to rapidly size a single-stage liquid oxygen (LOX) centrifugal pump and its axial inducer. Because 3D CFD simulations are computationally expensive, this 1D phase acts as a high-speed mathematical filter—ensuring only physically viable, highly efficient geometries are passed downstream to CFturbo and ANSYS.
%[text] ### Methodology and Execution
%[text] The  custom 1D script relies on Euler's turbomachinery equations and fundamental velocity triangles to predict hydraulic efficiency, pressure rise, and shaft torque. Real-fluid thermodynamics for subcooled LOX (via CoolProp fallback standards) were integrated to account for density shifts and accurately map vapor pressure.
%[text] Rather than relying on guess-and-check methodologies, we wrapped this 1D solver inside a parallelized Genetic Algorithm (GA). The optimizer was programmed to minimize a proportional penalty function, evaluating hundreds of thousands of candidate geometries against three strict physical and empirical constraints.
%[text] ### Core Governing Constraints
%[text] #### Empirical Geometry Limits (The NASA SP-8109 Cordier Line)
%[text] To prevent the optimizer from generating nonphysical impeller shapes (e.g., excessively wide or narrow profiles), designs were bench marked against historical aerospace pumps using two non-dimensional parameters:
%[text] - **Specific Speed (**$N\_S${"editStyle":"visual"}**):** Defines the optimal flow path shape. \
%[text]{"align":"center"} $N\_s = \\frac{\\omega \\cdot \\sqrt{Q}}{(g \\cdot H)^{3/4}}\n$
%[text] - **Specific Diameter (**$D\_S${"editStyle":"visual"}**):** Evaluates the physical size of the impeller. \
%[text]{"align":"center"} $D\_s = \\frac{d\_2 \\cdot (g \\cdot H)^{1/4}}{\\sqrt{Q}}$
%[text] The solver calculated the optimum Specific Diameter ($D\_{s,\\mathrm{opt}}${"editStyle":"visual"}) using the empirical Cordier curve. Geometries were strictly penalized if they fell outside the NASA SP-8109 tolerance band, forcing the algorithm to discard evolutionary  branches that drifted off the optimum ridge:
%[text]{"align":"center"} $0.75 \\le \\frac{D\_{s,actual}}{D\_{s,opt}} \\le 1.35\n$
%[text] #### Cavitation Mitigation (NPSH Limits)
%[text] To ensure the subcooled LOX does not boil as it accelerates into the pump, a hard cavitation constraint was applied to the inducer and main impeller eye. This is called the Net Positive Suction Head Available (${\\mathit{NPSH}}\_A${"editStyle":"visual"}):
%[text]{"align":"center"} $NPSH\_A = \\frac{P\_{suction} - P\_{vapor}}{\\rho \\cdot g} + \\frac{C\_m^2}{2g}$
%[text] The required NPSH (${\\mathit{NPSH}}\_R${"editStyle":"visual"}) was calculated based on the inducer's empirical suction specific speed. Any design failing the fundamental cavitation check triggered a massive flat penalty (+200), instantly killing the geometry's viability:
%[text]{"align":"center"} $NPSH\_A \\ge NPSH\_R + \\text{Safety Margin}$
%[text] #### Target Performance & The Fitness Landscape
%[text] To ensure the pump meets the exact requirements of the rocket engine, the solver calculated the actual pressure rise generated by the velocity triangles:
%[text]{"align":"center"} $\\Delta P\_{actual} = \\rho \\cdot g \\cdot H\_{euler} \\cdot \\eta\_h$
%[text] The objective function applied a proportional penalty based on how far the actual pressure drifted from the pressure target. This provided a continuous "gradient" for the Genetic Algorithm to follow down to the optimum design point:
%[text]{"align":"center"} $\\text{Penalty} = 15 \\times \\vert{} \\Delta P\_{actual} - \\Delta P\_{target} \\vert{}$
%[text] ### Optimizer using Global Optimization Toolbox 
%[text] #### Initialization
clear; clc; close all;
%[text] Initialize Parallel Pool
if isempty(gcp('nocreate'))
    fprintf('Starting Parallel Pool...\n');
    parpool; 
else
    fprintf('Parallel Pool already running.\n');
end
%[text] Define Decision Variables & Tightened Bounds (RATIO BASED)
%[text] `Variable Vector: x = [d2, b2_ratio, deye_ratio, b1_ratio, Z, N_rpm]`
%[text] *Note: We tighten the bounds around your working 78mm seed to give the GA a physically viable "sandbox" to explore.* 
lb = [70.0,  0.040, 0.45, 0.20, 5, 28000]; 
ub = [90.0,  0.080, 0.50, 0.40, 9, 40000];

IntCon = 5; % Z (Blade Count) must be an integer
%[text] Optimization Setup
TargetParams.Q_in = 250.0;          
TargetParams.dp_target_bar = 75.0;  
TargetParams.NPSH_required = 4.5;
TargetParams.fluid = 'Oxygen';      

% --- THE SEED ---
x_seed = [78.0, 0.059, 0.423, 0.303, 8, 35000];

% Configure Genetic Algorithm
opts = optimoptions('ga', ...
    'InitialPopulationMatrix', x_seed, ... 
    'UseParallel', true, ...           
    'UseVectorized', false, ...
    'PopulationSize', 1000, ...         
    'MaxGenerations', 300, ... 
    'MaxStallGenerations', 100, ...
    'FunctionTolerance', 1e-6, ...
    'Display', 'diagnose', ...
    'PlotFcn', {@gaplotbestf, @gaplotstopping});
%[text] Run Optimization
fprintf('\nStarting Parallel Optimization (300 Generations)... \n');
tic;

% Pass the TargetParams into the objective function wrapper
FitnessFcn = @(x) turbopump_objective(x, TargetParams);
[x_opt, fval_opt, exitflag, output] = ga(FitnessFcn, 6, [], [], [], [], lb, ub, [], IntCon, opts);

ExecutionTime = toc;
fprintf('\nOptimization Completed in %.2f seconds.\n', ExecutionTime);
%[text] #### Local Objective Function
function score = turbopump_objective(x, Target)
%[text] Decode Candidate Variables from Ratios
    d2   = x(1);
    b2   = max(d2 * x(2), 2.0);
    deye = max(d2 * x(3), 22.0);
    b1   = max(deye * x(4), 2.0);
    Z    = round(x(5));
    N    = x(6);
%[text] Build the ParSim Structure for this iteration
    ParSim.fluid.name = 'custom'; % Force custom to bypass CoolProp in parallel pool
    ParSim.fluid.temperature_K = 90.0;   
    ParSim.fluid.pressure_Pa = 5e5;      
    
    ParSim.operating.Q_in = Target.Q_in;            
    ParSim.operating.N_rpm = N;           
    ParSim.operating.dp_target_bar = Target.dp_target_bar; 
    ParSim.operating.p_suction_abs = 5e5;  
    ParSim.operating.p_vapor = 1.2e5;      
    ParSim.operating.NPSH_required = Target.NPSH_required; 
    
    % Geometry mapping
    ParSim.pump.d2 = d2;          
    ParSim.pump.b2 = b2;         
    ParSim.pump.deye = deye;
    ParSim.pump.Imp_inDia = deye; % Assuming eye matches inlet
    ParSim.pump.b1 = b1;        
    ParSim.pump.Z_LA = Z;         
    
    % Fixed Geometry (Not optimized by GA to save time)
    ParSim.pump.d3_i = d2 + 2.0; % Volute slightly larger than d2
    ParSim.pump.b3_i = b2 * 2.5; % Standard volute width rule of thumb
    ParSim.pump.D_hub = 20.0;     
    ParSim.pump.alphaTH = 2.0;    
    ParSim.pump.L_throat = 100.0;  
    
    ParSim.inducer.D_tip = deye;      
    ParSim.inducer.D_hub = 20.0;     
    ParSim.inducer.beta_tip = 12.0;               
    ParSim.inducer.eta_ind = 0.70;   
%[text] Run the Solvers inside a Try-Catch
    try
        % Inducer
        OutInducer = InducerSolver_1D(ParSim);
        
        % EXPLOIT FIX: If inducer acts as a turbine (negative pressure), kill it instantly
        if OutInducer.dp_inducer_bar <= 0
            error('Inducer turbine effect detected.'); 
        end
        
        ParSim.operating.p_suction_abs = ParSim.operating.p_suction_abs + OutInducer.dp_inducer_Pa;
        ParSim.operating.dp_target_bar = ParSim.operating.dp_target_bar - OutInducer.dp_inducer_bar;
        
        % Angles
        AngleOut = calculate_pump_blade_angles(ParSim);
        ParSim.pump.Beta_1 = AngleOut.Beta1_deg;
        ParSim.pump.Beta_2 = AngleOut.Beta2_deg;
        
        % Main Solver
        OutPump = HydSolver_1D(ParSim);
        
        % Extract Results
        eff = OutPump.efficiency;
        dP_actual = OutPump.pressure + OutInducer.dp_inducer_bar;
        Ds_ratio = AngleOut.Ds_ratio;
        cav_risk = OutPump.cavitation.cavitation_risk;

        % If angles fail, solver outputs NaNs or <10% eff. We must catch it here!
        if isnan(eff) || ~isreal(eff) || eff < 0.10 || dP_actual <= 0
            error('Solver returned fallback garbage due to impossible velocity triangles.');
        end
    catch
        % INSTANT DEATH PENALTY for broken physics
        % The GA will run away from this 1,000,000 score immediately.
        score = 1e6;
        return;
    end
%[text] Calculate Proportional Fitness Score
%[text] *Note: Base Score is to Maximize efficiency (Minimize negative efficiency)*
    % Base penalty: heavily punish low efficiency
    base_score = (1.0 - eff) * 1000; 
    
    % Quadratic Pressure Penalty for falling short (creates a steep slope toward 75 bar)
    if dP_actual < Target.dp_target_bar
        dP_penalty = (Target.dp_target_bar - dP_actual)^2 * 100;
    else
        dP_penalty = (dP_actual - Target.dp_target_bar) * 15; % Gentle trim for overdelivering
    end
    
    % Proportional Ds Ratio Penalty (Keep it within Cordier limits)
    Ds_penalty = 0;
    if Ds_ratio < 0.75
        Ds_penalty = 1000 * abs(0.75 - Ds_ratio);
    elseif Ds_ratio > 1.35
        Ds_penalty = 1000 * abs(Ds_ratio - 1.35);
    end
    
    % Cavitation Penalty
    cav_penalty = 0;
    if cav_risk
        cav_penalty = 1000; 
    end
    
    % Final Score (Lower is better)
    score = base_score + dP_penalty + Ds_penalty + cav_penalty;
end
%[text] Display Optimal Results
%[text] *Note: Convert Ratios back to Physical Millimeters for Printing*
d2_opt = x_opt(1);
b2_opt = max(d2_opt * x_opt(2), 2.0);
deye_opt = max(d2_opt * x_opt(3), 22.0);
b1_opt = max(deye_opt * x_opt(4), 2.0);
Z_opt = round(x_opt(5));
N_rpm_opt = x_opt(6);

fprintf('\n=======================================\n');
fprintf('       OPTIMAL PUMP GEOMETRY\n');
fprintf('=======================================\n');
fprintf('Impeller OD (d2)    : %.2f mm\n', d2_opt);
fprintf('Outlet Width (b2)   : %.2f mm\n', b2_opt);
fprintf('Eye Diameter (deye) : %.2f mm\n', deye_opt);
fprintf('Inlet Width (b1)    : %.2f mm\n', b1_opt);
fprintf('Blade Count (Z)     : %d\n', Z_opt);
fprintf('Shaft Speed (N)     : %.0f RPM\n', N_rpm_opt);
fprintf('Final Penalty Score : %.2f\n', fval_opt);
fprintf('=======================================\n\n');
%[text] #### Re-Run Full Simulation on Optimal Point for Detailed Stats
%[text] Build ParSim for the optimum point
ParSim.fluid.name = 'Oxygen';        % Re-enable CoolProp for the final accurate check
ParSim.fluid.temperature_K = 90.0;   % Match target parameters
ParSim.fluid.pressure_Pa = 5e5;

ParSim.operating.Q_in = TargetParams.Q_in;
ParSim.operating.N_rpm = N_rpm_opt;
ParSim.operating.dp_target_bar = TargetParams.dp_target_bar;
ParSim.operating.p_suction_abs = 5e5;
ParSim.operating.p_vapor = 1.2e5;
ParSim.operating.NPSH_required = TargetParams.NPSH_required;

ParSim.pump.d2 = d2_opt;
ParSim.pump.b2 = b2_opt;
ParSim.pump.deye = deye_opt;
ParSim.pump.Imp_inDia = deye_opt;
ParSim.pump.b1 = b1_opt;
ParSim.pump.Z_LA = Z_opt;

% Fixed dimensions
ParSim.pump.d3_i = d2_opt + 2.0;
ParSim.pump.b3_i = b2_opt * 2.5;
ParSim.pump.D_hub = 20.0;
ParSim.pump.alphaTH = 2.0;
ParSim.pump.L_throat = 100.0;

ParSim.inducer.D_tip = deye_opt;
ParSim.inducer.D_hub = 20.0;
ParSim.inducer.beta_tip = 12.0;
ParSim.inducer.eta_ind = 0.70;
%[text] Run the 3 solvers sequentially
OutInducer = InducerSolver_1D(ParSim);
ParSim.operating.p_suction_abs = ParSim.operating.p_suction_abs + OutInducer.dp_inducer_Pa;
ParSim.operating.dp_target_bar = ParSim.operating.dp_target_bar - OutInducer.dp_inducer_bar;

AngleOut = calculate_pump_blade_angles(ParSim);
ParSim.pump.Beta_1 = AngleOut.Beta1_deg;
ParSim.pump.Beta_2 = AngleOut.Beta2_deg;

OutPump = HydSolver_1D(ParSim);
%[text] Print Final Stats (Using requested format)
disp('==================== PUMP METRICS ====================');
fprintf('Pressure Rise       : %.2f bar\n', OutPump.pressure + OutInducer.dp_inducer_bar);
fprintf('Shaft Torque        : %.2f Nm\n', OutPump.torque);
fprintf('Hydraulic Efficiency: %.2f %%n', OutPump.efficiency * 100);
fprintf('Axial Thrust Force  : %.2f N\n', OutPump.F_axial);

disp('================ CALCULATED ANGLES ===================');
fprintf('Inlet Blade Angle (Beta 1) : %.2f deg\n', OutPump.calculated_angles.Beta1_deg);
fprintf('Outlet Blade Angle (Beta 2): %.2f deg\n', OutPump.calculated_angles.Beta2_deg);
fprintf('Flow Deviation Angle       : %.2f deg\n', AngleOut.deviation_deg);

disp('============== INDUCER STAGE RESULTS =================');
fprintf('Inducer Axial Velocity (Cz): %.2f m/s\n', OutInducer.c_z);
fprintf('Inducer Tip Speed (Utip)   : %.2f m/s\n', OutInducer.u_tip);
fprintf('Inducer Pressure Rise      : %.2f bar\n\n', OutInducer.dp_inducer_bar);

disp('============== NASA SP-8109 SCREENING ================');
fprintf('Non-Dim Specific Speed (Ns): %.3f\n', AngleOut.Ns_nondim);
fprintf('Non-Dim Specific Dia   (Ds): %.3f (Optimum: %.3f)\n', AngleOut.Ds_nondim, AngleOut.Ds_opt);
fprintf('Ds Ratio (Ds / Ds_opt)    : %.2f\n', AngleOut.Ds_ratio);
if AngleOut.NASA_SP8109_viable
    disp('NASA SP-8109 Viability      : PASS (Geometry sits near Cordier optimum)');
else
    disp('NASA SP-8109 Viability      : WARNING (Geometry deviates significantly from Cordier optimum)');
end

disp('================ CAVITATION CHECK ====================');
fprintf('NPSH Available : %.2f m\n', OutPump.cavitation.NPSH_available_m);
fprintf('NPSH Required  : %.2f m\n', OutPump.cavitation.NPSH_required_m);
fprintf('NPSH Margin    : %.2f m\n', OutPump.cavitation.NPSH_margin_m);
fprintf('Cavitation Status: %s\n', OutPump.cavitation.status);
%%
%[text] ## 1D Axial Inducer Simulation
%[text] The axial inducer that leads into the impeller eye is responsible for 8-12% of the energy addition in the turbopump system. It also, crucially, helps avoid cavitation by increasing the pressure into the impeller which also contributes to a more efficient pressure rise. This script is a mean-line analytical model for the inducer based on the Euler pump equation and is intended to be run before the main centrifugal pump calculations.
%[text] ### Key Governing Equations
%[text] For an axial inducer, the theoretical Euler Head ($H\_{\\mathrm{ind}}${"editStyle":"visual"}) is calculated using the blade tip speed ($U\_{\\mathrm{tip}}${"editStyle":"visual"}), the axial flow velocity ($C\_z${"editStyle":"visual"}), and the inducer tip blade angle ($\\beta\_{\\mathrm{tip}}${"editStyle":"visual"}):
%[text] #### Axial Velocity
%[text]{"align":"center"} $C\_z =\\frac{Q}{A\_{\\mathrm{eye}} }${"editStyle":"visual"}
%[text] #### Tip Tangential Velocity
%[text]{"align":"center"} $C\_{\\theta 2} =U\_{\\mathrm{tip}} -\\frac{C\_z }{\\tan \\left(\\beta\_{\\mathrm{tip}} \\right)}${"editStyle":"visual"}
%[text] #### Inducer Head
%[text]{"align":"center"} $H\_{\\mathrm{ind}} =\\frac{U\_{\\mathrm{tip}} \\cdot C\_{\\theta 2} }{g\\;}${"editStyle":"visual"}
%[text] ### **Underlying Assumptions**
%[text] #### Conservative efficiency estimate
%[text] When we convert the calculated head into a an actual pressure rise ($\\Delta P\_{\\mathrm{ind}}${"editStyle":"visual"}) using a conservative inducer hydraulic efficiency estimate ($\\eta\_{\\mathrm{ind}} \\approx 70${"editStyle":"visual"}, as inducers are designed for cavitation resistance not peak efficiency). 
%[text] ### Run 1D Axial Inducer Solver
function OutInducer = InducerSolver_1D(ParSim)
%[text] Kinematics and Flow Area
A_ind_m2 = (pi/4) * ((ParSim.inducer.D_tip/1000)^2 - (ParSim.inducer.D_hub/1000)^2);
Q_m3s = ParSim.operating.Q_in * 1e-3 / 60;
c_z = Q_m3s / A_ind_m2;                                                              % Axial flow velocity [m/s]
u_tip = (pi * ParSim.operating.N_rpm * (ParSim.inducer.D_tip/1000)) / 60;            % Tip speed [m/s]

OutInducer.c_z = c_z;
OutInducer.u_tip = u_tip;
%[text] Velocity Triangle and Euler Head 
%[text] *Note: Assuming zero pre-whirl entering the inducer (*$C\_{\\mathrm{u1}}${"editStyle":"visual"}*).*
c_u2_ind = u_tip - (c_z / tan(deg2rad(ParSim.inducer.beta_tip)));
H_inducer = (u_tip * c_u2_ind) / 9.81;         % Ideal Euler Head [m]
%[text] Calculating Inducer Pressure Rise
fluidProps = getFluidProperties(ParSim);
rho_propellant = fluidProps.rho;
dp_inducer_Pa = rho_propellant * 9.81 * H_inducer * ParSim.inducer.eta_ind;
dp_inducer_bar = dp_inducer_Pa / 1e5;

OutInducer.dp_inducer_Pa = dp_inducer_Pa;
OutInducer.dp_inducer_bar = dp_inducer_bar;

end
%%
%[text] ## Calculating Pump's Blade Angles
%[text] This script is an inverse-design pre-processor routine. It calculates the geometric blade metal angles at the impeller inlet ($\\beta\_{1B}${"editStyle":"visual"}) and outlet ($\\beta\_{2B}${"editStyle":"visual"}) prior to running full hydraulic performance sweeps. This step ensures that the generated impeller geometry satisfies target head requirements under real fluid slip and prescribed flow incidence conditions.
%[text] ### **Key Governing Equations**
%[text] #### **Inlet Velocity Triangle & Relative Blade Angle**
%[text] Meridional velocity at the inlet eye is calculated by accounting for hub/tip dimensions and blade thickness blockage:
%[text]{"align":"center"} $&dollar&;&dollar&;A\_1 = \\frac{\\pi}{4}\\left(D\_{\\text{eye}}^2 - D\_{\\text{hub}}^2\\right) \\cdot \\lambda\_1$ 
%[text]{"align":"center"} $\\quad c\_{m1} = \\frac{Q}{A\_1}\\$
%[text]{"align":"center"} $\\beta\_{1,\\text{flow}} = \\arctan\\left(\\frac{c\_{m1}}{u\_1 - c\_{u1}}\\right)$
%[text]{"align":"center"} $\\beta\_{1B} = \\beta\_{1,\\text{flow}} + i$
%[text] where $&dollar&;\\lambda\_1 = \\max\\left(1 - \\frac{Z t}{\\pi D\_{\\text{mean}}}, 0.05\\right)&dollar&;$, $&dollar&;u\_1 = \\omega r\_{1,\\text{local}}&dollar&;,  &dollar&;c\_{u1}&dollar&;$ is the inlet pre-whirl velocity, and $i${"editStyle":"visual"} is the specified incidence angle. 
%[text] These equations are derived from the velocity triangle which are as follows:
%[text]{"align":"center"} ![](text:image:684e) ![](text:image:9617)
%[text]{"align":"center"} Figure 1a and 1b. Inlet velocity and outlet velocity triangle (CFturbo manual).
%[text] #### **Required Euler Head & Target Tangential Velocity**
%[text]{"align":"center"} $&dollar&;&dollar&;H\_{e,\\text{req}} = \\frac{H\_{\\text{target}}}{\\eta\_{h,\\text{guess}}}$
%[text]{"align":"center"} $c\_{u2,\\text{req}} = \\frac{g H\_{e,\\text{req}} + u\_1 c\_{u1}}{u\_2}$
%[text] #### **Slip Factor Coupling & Outlet Angle Residual Solver**
%[text] The required outlet blade metal angle $&dollar&;\\beta\_{2B}&dollar&;$ is determined implicitly using a 1D root-finding algorithm (`fzero`) that balances the required tangential velocity against slip-corrected ideal whirl:
%[text]{"align":"center"} $&dollar&;&dollar&;R(\\beta\_{2B}) = \\sigma(\\beta\_{2B}, Z, D\_1/D\_2, \\beta\_{1B}) \\cdot c\_{u2,\\text{ideal}}(\\beta\_{2B}) - c\_{u2,\\text{req}} = 0$
%[text]{"align":"center"} $c\_{u2,\\text{ideal}}(\\beta\_{2B}) = u\_2 - c\_{m2} \\cot(\\beta\_{2B})$
%[text] **El-Naggar Base Slip Factor Correlation (**$&dollar&;\\sigma&dollar&;$**):** 
%[text]{"align":"center"} $\\sigma\_0 = 1 - \\frac{\\sqrt{\\sin(\\pi - \\beta\_{2B})}}{Z^{0.7}} \\left\[ 1 - \\left(\\frac{d\_1/d\_2 - e\_{\\text{limit}}}{1 - e\_{\\text{limit}}}\\right)^{1/3} \\frac{1}{\\pi - \\beta\_{1B}} \\right\]$
%[text] where $e\_{\\text{limit}} = \\exp\\left(\\frac{-8.16 \\sin(\\pi - \\beta\_{2B})}{Z}\\right)$.
%[text] ### **Underlying Assumptions**
%[text] #### **Uniform Axisymmetric Flow**
%[text] Velocities ($&dollar&;c\_{m1}, c\_{m2}&dollar&;$) are assumed uniform across the inlet span and discharge width.
%[text] **Constant Initial Efficiency Guess**
%[text] Required Euler head relies on a constant initial hydraulic efficiency estimate ($&dollar&;\\eta\_{h,\\text{guess}}&dollar&;$). The guess is extracted from the example rocket turbopump CFturbo file.
%[text] #### **1D Slip Representation**
%[text] Blade-to-blade flow deviation is captured entirely by empirical slip factor correlations without modeling 3D secondary flow structures.
%[text] #### **Linear Blockage Approximation**
%[text] Metal blockage at the inlet and outlet is approximated using standard circumferential blade thickness ratios.
%[text] ### Run Blade Angle Calculations
function AngleOut = calculate_pump_blade_angles(ParSim)

validateRequiredInputs(ParSim);

g = 9.81;
N = ParSim.operating.N_rpm;
%[text] Get dynamic thermodynamic fluid properties
fluidProps = getFluidProperties(ParSim);
rho = fluidProps.rho;
Q = ParSim.operating.Q_in * 1e-3 / 60;   % L/min to m^3/s
%[text] Geometric and operating properties
eta_h_guess = getConst(ParSim, 'eta_h_guess', 0.64);
cu1 = getConst(ParSim, 'inlet_prewhirl', 0.0);
span = getConst(ParSim, 'inlet_span', 0.5);
incidence_deg = getConst(ParSim, 'incidence_deg', 0.0);
beta2_bounds_deg = getConst(ParSim, 'beta2_bounds_deg', [15 70]);

Deye = ParSim.pump.deye * 1e-3;
Dhub = ParSim.pump.D_hub * 1e-3;
D2   = ParSim.pump.d2 * 1e-3;
b2   = ParSim.pump.b2 * 1e-3;
Z    = ParSim.pump.Z_LA;
t    = getConst(ParSim, 'e1', 1.5) * 1e-3;

if Deye <= Dhub
    error('calculate_pump_blade_angles:BadEyeGeometry', 'deye must be greater than D_hub.');
end
if span < 0 || span > 1
    error('calculate_pump_blade_angles:BadSpan', 'inlet_span must be between 0 and 1.');
end
if eta_h_guess <= 0 || eta_h_guess > 1
    error('calculate_pump_blade_angles:BadEfficiency', 'eta_h_guess must be between 0 and 1.');
end

omega = 2 * pi * N / 60;
%[text] Inlet Blade Angle (Zero-Incidence or Specified Incidence)
if hasConst(ParSim, 'inlet_blockage')
    blockage1 = getConst(ParSim, 'inlet_blockage', 1.0);
else
    DmeanEye = 0.5 * (Deye + Dhub);
    blockage1 = max(1 - (Z * t / (pi * DmeanEye)), 0.05);
end

A1 = (pi / 4) * (Deye^2 - Dhub^2) * blockage1;
cm1 = Q / A1;
D1_local = Dhub + span * (Deye - Dhub);
r1_local = D1_local / 2;
u1 = omega * r1_local;

beta1_flow = atan2(cm1, max(u1 - cu1, eps));
beta1B = beta1_flow + deg2rad(incidence_deg);

%[text] Outlet Blade Angle from Required Euler Head and Slip Correlation
if hasConst(ParSim, 'outlet_blockage')
    blockage2 = getConst(ParSim, 'outlet_blockage', 1.0);
else
    blockage2 = max(1 - (Z * t / (pi * D2)), 0.05);
end

A2 = pi * D2 * b2 * blockage2;
cm2 = Q / A2;
u2 = omega * D2 / 2;

H_target = getTargetHead(ParSim, rho, g);
H_euler_required = H_target / eta_h_guess;
cu2_required = (g * H_euler_required + u1 * cu1) / u2;

beta_lo = deg2rad(beta2_bounds_deg(1));
beta_hi = deg2rad(beta2_bounds_deg(2)) + pi;

residual = @(b2B) outletWhirlResidual(b2B, u2, cm2, cu2_required, Z, Dhub/D2, beta1B);
f_lo = residual(beta_lo);
f_hi = residual(beta_hi);

if ~isfinite(f_lo) || ~isfinite(f_hi) || sign(f_lo) == sign(f_hi)
    beta_grid = linspace(beta_lo, beta_hi, 300);
    f_grid = arrayfun(residual, beta_grid);
    idx = find(isfinite(f_grid(1:end-1)) & isfinite(f_grid(2:end)) & (sign(f_grid(1:end-1)) .* sign(f_grid(2:end)) <= 0), 1, 'first');
    if isempty(idx)
        error('calculate_pump_blade_angles:NoBeta2Solution', ...
            'No beta2 solution exists inside %.1f to %.1f deg. Check target head, eta_h_guess, D2, b2, and RPM.', ...
            beta2_bounds_deg(1), beta2_bounds_deg(2));
    end
    beta_lo = beta_grid(idx);
    beta_hi = beta_grid(idx+1);
end

beta2B = pi - fzero(residual, [beta_lo, beta_hi]);
sigma = originalBaseSlipFactor(beta2B, Z, Dhub/D2, beta1B);
cu2_ideal = u2 - cm2 * cot(beta2B);
cu2_actual = sigma * cu2_ideal;
beta2_flow = atan2(cm2, max(u2 - cu2_actual, eps));
deviation = beta2B - beta2_flow;
%[text] #### Notes on NASA SP-8109
%[text] NASA SP-8109 (*Liquid Rocket Engine Centrifugal Flow Turbopumps*, published in 1973) is a comprehensive design monograph compiled during the Apollo era. It synthesizes decades of empirical flight and test-stand data from historical liquid engine turbopumps (such as the F-1, J-2, RL10, and Titan engines) into standardized design guidelines, loss trends, and geometric scaling laws. Its core concept is the Cordier / Balje ($N\_s -D\_s${"editStyle":"visual"}) Optimal Line. When designing a turbopump, your mission requirements usually fix three variables: **required flow rate (**$Q${"editStyle":"visual"}**), required pressure rise/head (**$H${"editStyle":"visual"}**), and shaft rotational speed (**$N${"editStyle":"visual"}**).**
%[text] To determine the ideal physical dimensions of the impeller without blind guessing, NASA SP-8109 uses two non-dimensional numbers:
%[text] **1. Non-Dimensional Specific Speed (**$N\_s${"editStyle":"visual"}**):** Describes the hydraulic "type" of the pump (radial, mixed-flow, or axial):
%[text]{"align":"center"} $N\_s = \\frac{\\omega \\sqrt{Q}}{(g H)^{0.75}}$
%[text] **2. Non-Dimensional Specific Diameter (**$D\_2${"editStyle":"visual"}**):** Relates the outer impeller diameter ($D\_2${"editStyle":"visual"}) to flow and head:
%[text]{"align":"center"} $D\_s = \\frac{D\_2 (g H)^{0.25}}{\\sqrt{Q}}$
%[text] When thousands of tested pumps are plotted on an $N\_s${"editStyle":"visual"} vs. $D\_s${"editStyle":"visual"} chart, peak hydraulic efficiency collapses along a narrow curve known as the **Cordier Line**:
%[text]{"align":"center"} $&dollar&;&dollar&;D\_s \\approx \\frac{2.16}{N\_s^{0.6}}&dollar&;&dollar&;$$\\;\\cdot \\;2${"editStyle":"visual"}
%[text] By integrating this, the code is able to flag candidates that deviate significantly from optimal proportions ($D\_s \\;/D\_{s,\\mathrm{opt}}${"editStyle":"visual"} ratio outside $0\\ldotp 75-1\\ldotp 35${"editStyle":"visual"}) before running full loss iterations. It also, crucially, allows the sizing of an initial diameter ($D\_2${"editStyle":"visual"}) given an RPM, or vice versa.
%[text] NASA SP-8109 Specific Speed & Diameter Check
% Catch imaginary, negative, or NaN head before power operations
if H_target <= 0 || ~isreal(H_target) || isnan(H_target)
    error('calculate_pump_blade_angles:InvalidHead', 'Target head is negative, NaN, or imaginary.');
end

Ns_nondim = omega * sqrt(Q) / (g * H_target)^0.75;  % Non-dimensional Ns

% Catch imaginary specific speed before hitting the Cordier power curve (0.6)
if ~isreal(Ns_nondim) || isnan(Ns_nondim) || Ns_nondim <= 0
     error('calculate_pump_blade_angles:InvalidNs', 'Specific speed is complex or NaN.');
end

Ds_nondim = D2 * (g * H_target)^0.25 / sqrt(Q);     % Non-dimensional Ds
Ds_opt = (2.16 / (Ns_nondim^0.6)) * 2;              % NASA SP-8109 / Cordier optimum fit
Ds_ratio = Ds_nondim / Ds_opt;                      % Near 1.0 is optimal
%[text] Package Results
AngleOut.Beta1_deg = rad2deg(beta1B);
AngleOut.Beta2_deg = rad2deg(beta2B);
AngleOut.Beta1_flow_deg = rad2deg(beta1_flow);
AngleOut.Beta2_flow_deg = rad2deg(beta2_flow);
AngleOut.incidence_deg = rad2deg(beta1B - beta1_flow);
AngleOut.deviation_deg = rad2deg(deviation);
AngleOut.sigma_design = sigma;
AngleOut.H_target_m = H_target;
AngleOut.H_euler_required_m = H_euler_required;
AngleOut.cu2_required_mps = cu2_required;
AngleOut.cu2_actual_mps = cu2_actual;
AngleOut.cm1_mps = cm1;
AngleOut.cm2_mps = cm2;
AngleOut.u1_mps = u1;
AngleOut.u2_mps = u2;
AngleOut.A1_m2 = A1;
AngleOut.A2_m2 = A2;
AngleOut.blockage1 = blockage1;
AngleOut.blockage2 = blockage2;
AngleOut.inlet_span = span;
AngleOut.deviation_warning = abs(AngleOut.deviation_deg) > 14;
%[text] NASA SP-8109 screening flags
AngleOut.Ns_nondim = Ns_nondim;
AngleOut.Ds_nondim = Ds_nondim;
AngleOut.Ds_opt = Ds_opt;
AngleOut.Ds_ratio = Ds_ratio;
AngleOut.NASA_SP8109_viable = (Ds_ratio >= 0.75 && Ds_ratio <= 1.35);

end
%[text] Helper Functions
function r = outletWhirlResidual(beta2B, u2, cm2, cu2Required, Z, d1d2, beta1B)
    sigma = originalBaseSlipFactor(beta2B, Z, d1d2, beta1B);
    cu2Ideal = u2 - cm2 * cot(beta2B);
    r = sigma * cu2Ideal - cu2Required;
end

function sigma0 = originalBaseSlipFactor(beta2B, Z, d1d2, beta1B)
    beta2Corr = pi - beta2B;
    beta1Corr = pi - beta1B;
    eLimit = exp(-8.16 * sin(beta2Corr) / Z);
    if eLimit >= d1d2
        sigma0 = 1 - sqrt(sin(beta2Corr)) / (Z^0.7);
    else
        ratioTerm = max((d1d2 - eLimit) / (1 - eLimit), 0);
        sigma0 = 1 - (sqrt(sin(beta2Corr)) * (1 - ratioTerm^(1/3))) / (beta1Corr * (Z^0.7));
    end
    sigma0 = min(max(sigma0, 0.01), 0.999);
end

function H = getTargetHead(ParSim, rho, g)
    if isfield(ParSim.operating, 'H_target_m')
        H = ParSim.operating.H_target_m;
    elseif isfield(ParSim.operating, 'dp_target_Pa')
        H = ParSim.operating.dp_target_Pa / (rho * g);
    elseif isfield(ParSim.operating, 'dp_target_bar')
        H = ParSim.operating.dp_target_bar * 1e5 / (rho * g);
    elseif isfield(ParSim.operating, 'P_in')
        H = ParSim.operating.P_in * 1e5 / (rho * g);
    else
        error('calculate_pump_blade_angles:MissingTarget', 'Provide H_target_m, dp_target_Pa, or dp_target_bar.');
    end
end
%[text] #### Notes on CoolProp
%[text] CoolProp is a high-accuracy thermophysical property database (similar to NIST REFPROP). It uses High-Accuracy Helmholtz Energy Equations of State (HEOS) to evaluate real-fluid properties across subcooled, saturated, two-phase, and super-critical regimes. In liquid rocket engines, propellants like **Liquid Oxygen (LOX)**, **Liquid Methane (**${\\mathrm{LCH}}\_4${"editStyle":"visual"}**)**, and **Liquid Hydrogen (**${\\mathrm{LH}}\_2${"editStyle":"visual"}**)** behave very differently:
%[text] - **Subcooling & Density Sensitivity:** Subcooled LOX density changes noticeably with temperature. A $5\\;K${"editStyle":"visual"} shift in propellant feed temperature alters fluid density ($\\rho${"editStyle":"visual"}), directly changing the volumetric flow rate ($Q = \\dot{m} / \\rho$) for a fixed mass flow. This requires a different inlet eye radius ($r\_{\\mathrm{in}}${"editStyle":"visual"}) and tip radius ($R\_{\\mathrm{out}}${"editStyle":"visual"}) to maintain velocity triangles.
%[text] - **Vapor Pressure & Cavitation (**$\\mathrm{NPSH}${"editStyle":"visual"}**):** Vapor pressure ($P\_{\\mathrm{vap}}${"editStyle":"visual"}) rises exponentially with temperature. If local pressure inside the blade passage drops below $P\_{\\mathrm{vap}}${"editStyle":"visual"}, vapor bubbles form and collapse violently (cavitation), destroying performance and damaging hardware. \
%[text]{"align":"center"} $\\text{NPSH}\_{\\text{available}} = \\frac{P\_{\\text{suction,abs}} - P\_{\\text{vapor}}(T)}{\\rho(T, P) \\cdot g} + \\frac{v\_{\\text{suction}}^2}{2g}$
%[text] By integrating CoolProp into the code, the following benefits are realized:
%[text] - **Dynamic** $P\_{\\mathrm{vap}}${"editStyle":"visual"}**:** The code evaluates $P\_{\\mathrm{vap}}${"editStyle":"visual"} dynamically based on fluid temperature $T${"editStyle":"visual"}, producing an accurate Net Positive Suction Head ($\\mathrm{NPSHa}${"editStyle":"visual"}) assessment.
%[text] - **Mass Flow** $\\longleftrightarrow${"editStyle":"visual"} **Volume Flow Link:** The solver evaluates fluid state $\\left(T,P\\right)${"editStyle":"visual"} to convert mass flow rates into true volumetric velocity vectors $\\left(c\_{\\mathrm{m1}} ,c\_{\\mathrm{m2}} \\right)${"editStyle":"visual"}.
%[text] - **Multi-Propellant Flexibility:** You can switch the fluid input string in `ParSim.fluid.name` between `'Oxygen'`, `'Methane'`, `'Hydrogen'`, or `'RP-1'` without needing to manually look up and rewrite fluid constants. Though, this would be outside the scope of this particular project.  \
function props = getFluidProperties(ParSim)
    % CoolProp dynamic thermal database integration with static fallback
    if isfield(ParSim, 'fluid') && isfield(ParSim.fluid, 'name') && ~strcmp(ParSim.fluid.name, 'custom')
        try
            fluid = ParSim.fluid.name;
            T_K = ParSim.fluid.temperature_K;
            P_Pa = ParSim.fluid.pressure_Pa;
            
            % Call CoolProp via MATLAB Python interface
            props.rho = double(py.CoolProp.CoolProp.PropsSI('D', 'T', T_K, 'P', P_Pa, fluid));
            mu = double(py.CoolProp.CoolProp.PropsSI('V', 'T', T_K, 'P', P_Pa, fluid));
            props.nu = mu / props.rho;
            props.p_vapor = double(py.CoolProp.CoolProp.PropsSI('P', 'T', T_K, 'Q', 0, fluid));
            return;
        catch
            warning('CoolProp call failed or unconfigured. Falling back to constant inputs.');
        end
    end
    
    % Fallback to user-defined constants
    props.rho = getConst(ParSim, 'rho_propellant', 1049.0);
    props.nu = getConst(ParSim, 'Nu', 5.0e-7);
    props.p_vapor = getConst(ParSim, 'p_vapor_default', 1.0e5);
end

function value = getConst(ParSim, name, defaultValue)
    if isfield(ParSim, 'constants') && isfield(ParSim.constants, name)
        value = ParSim.constants.(name);
    else
        value = defaultValue;
    end
end

function tf = hasConst(ParSim, name)
    tf = isfield(ParSim, 'constants') && isfield(ParSim.constants, name);
end

function validateRequiredInputs(ParSim)
    requiredOperating = {'N_rpm', 'Q_in'};
    requiredPump = {'deye', 'D_hub', 'd2', 'b2', 'Z_LA'};
    for k = 1:numel(requiredOperating)
        if ~isfield(ParSim, 'operating') || ~isfield(ParSim.operating, requiredOperating{k})
            error('calculate_pump_blade_angles:MissingInput', 'Missing ParSim.operating.%s', requiredOperating{k});
        end
    end
    for k = 1:numel(requiredPump)
        if ~isfield(ParSim, 'pump') || ~isfield(ParSim.pump, requiredPump{k})
            error('calculate_pump_blade_angles:MissingInput', 'Missing ParSim.pump.%s.', requiredPump{k});
        end
    end
end
%%
%[text] ## 1D Hydraulic Pump Simulation
%[text] This script is a forward performance prediction module based on El-Naggar's 1D loss modeling framework. It evaluates the complete head-capacity ($H-Q${"editStyle":"visual"}), shaft power, hydraulic efficiency, and cavitation curves across a discretized range of flow coefficients.
%[text] ### **Key Governing Equations**
%[text] #### **Non-Dimensional Flow & Head Iteration Loop**
%[text] The solver iteratively determines internal flow parameter $\\phi${"editStyle":"visual"} and theoretical head coefficient ${\\mathrm{CH}}\_0${"editStyle":"visual"} by balancing impeller performance against volute and passage head losses:
%[text]{"align":"center"} $\\phi = -\\frac{1}{2}\\epsilon \\cot(\\beta\_2) + \\frac{1}{2}\\sqrt{\\left(\\epsilon \\cot(\\beta\_2)\\right)^2 + \\frac{2}{\\sigma x}}$
%[text]{"align":"center"} $CH\_0 = \\sigma \\cdot \\left(1 + \\frac{\\epsilon \\cot(\\beta\_2)}{\\phi}\\right)$
%[text] where $x = \\frac{1}{1 + h\_{lv,\\text{ratio}} + h\_{l,\\text{eye,ratio}}}$ is the head loss attenuation factor.
%[text] #### **Volute Hydraulic Loss Model** 
%[text]{"align":"center"} $h\_{lv,\\text{ratio}} = C\_{fv} CV\_{3p}^2 + C\_{dv} CV\_{3d}^2 + CV\_{3r}^2 + C\_{f,\\text{th}} CV\_4^2$
%[text] Friction factor ($f\_v${"editStyle":"visual"}) depends on local volute Reynolds number (${\\mathrm{Re}}\_v${"editStyle":"visual"}):
%[text]{"align":"center"} $f\_v = \\frac{0.3086}{\\left\[ \\log\_{10}\\left(\\frac{6.9}{Re\_v} + \\left(\\frac{k\_{dhv}}{3.7}\\right)^{1.11}\\right) \\right\]^2}$
%[text] #### **Parasitic Power Losses & Shaft Head**
%[text] Total shaft head coefficient ${\\mathit{CH}}\_{\\mathit{shaft}}${"editStyle":"visual"} combines ideal head, blade friction ($C\_{h,\\mathrm{lf}}${"editStyle":"visual"}), disc friction ($C\_{h,\\mathrm{disc}}${"editStyle":"visual"}), inlet recirculation ($C\_{h,\\mathrm{circ},\\mathrm{in}}${"editStyle":"visual"}), and volumetric leakage ($C\_{h,\\mathrm{leakage}}${"editStyle":"visual"}):
%[text]{"align":"center"} $CH\_{\\text{shaft}} = CH\_0 + C\_{h,lf} + C\_{h,\\text{circ,in}} + C\_{h,\\text{leakage}} + C\_{h,\\text{disc}$
%[text]{"align":"center"} $\\eta\_{\\text{hyd}} = \\frac{CH}{CH\_{\\text{shaft}}}$
%[text] #### **Net Positive Suction Head (NPSH) & Cavitation Assessment**
%[text]{"align":"center"} $v\_{\\text{suction}} = \\frac{Q}{A\_{\\text{suction}}}$,     $A\_{\\text{suction}} = \\frac{\\pi}{4}\\left(D\_{\\text{eye}}^2 - D\_{\\text{hub}}^2\\right)\n$
%[text]{"align":"center"} $NPSHA = \\frac{p\_{\\text{suction,abs}} - p\_{\\text{vapor}}}{\\rho g} + \\frac{v\_{\\text{suction}}^2}{2g}\n$
%[text]{"align":"center"} $\\text{Cavitation Risk Flag: } NPSHa \\le NPSHr$
%[text] ### **Underlying Assumptions**
%[text] #### **Static Loss Coefficients**
%[text] Loss parameters ($C\_{\\mathrm{dl}} \\;,C\_{\\mathrm{dv}}${"editStyle":"visual"}) and passage surface roughness values ($k\_{\\mathrm{volute}} \\;,k\_{\\mathrm{impeller}}${"editStyle":"visual"}) remain constant across off-design operating conditions.
%[text] #### **Enclosed Disk Friction Models**
%[text] Disc friction torque loss relies on standard Daily & Nece empirical turbulent flow regimes for smooth, enclosed rotating disks.
%[text] #### **Single-Phase Fluid Dynamics**
%[text] Loss correlations assume single-phase liquid flow throughout the operating range. Performance breakdown due to vapor phase formation during severe cavitation is flagged as a failure state rather than modeled as two-phase flow.
%[text] ### Run 1D Hydraulic Solver with CoolProp
function [OutPump] = HydSolver_1D(ParSim)

plt_option = 0;
eAx_option = 0;
g = 9.81;
%[text] Fluid Properties (CoolProp Integration)
fluidProps = getFluidProperties2(ParSim);
rho = fluidProps.rho;
Nu = fluidProps.nu;
%[text] Pump Geometry & Operating Parameters
d2 = ParSim.pump.d2;
N = ParSim.operating.N_rpm;
b2 = ParSim.pump.b2;
d1 = ParSim.pump.Imp_inDia;
b1 = ParSim.pump.b1;
Z_LA = ParSim.pump.Z_LA;
d3_i = ParSim.pump.d3_i;
b3_i = ParSim.pump.b3_i;
deye = ParSim.pump.deye;
alphaTH = ParSim.pump.alphaTH;
L_throat = ParSim.pump.L_throat;

Beta1_deg = ParSim.pump.Beta_1;
Beta2_deg = ParSim.pump.Beta_2;
%[text] El-Naggar correlations use transformed angles (180 - Beta)
Beta2 = pi - deg2rad(Beta2_deg);
Beta1 = pi - deg2rad(Beta1_deg);
%[text] Fixed / Calibration Constants
cdl = getConst2(ParSim, 'cdl', 0.60);
Cdv = getConst2(ParSim, 'ceye', 1.00);
k_volute_i = getConst2(ParSim, 'k_volute_i', 1.0e-4);
k_impeller_i = getConst2(ParSim, 'k_impeller_i', 1.0e-4);
NPoints = getConst2(ParSim, 'NPoints', 80);
slipLossMulti = getConst2(ParSim, 'slipLossMulti', 1.0);
Cd_impeller = getConst2(ParSim, 'Cd_impeller', 0.02);

y_gap = getConst2(ParSim, 'y_gap', 0.50);
yc_i = getConst2(ParSim, 'yc_i', 0.50);
e1 = getConst2(ParSim, 'e1', 1.5);

drotor = getConst2(ParSim, 'D_o_bi', d2);
di_stator = getConst2(ParSim, 'D_i_stator', 15.0);
Motor_D_o = getConst2(ParSim, 'D_o', d2);
Rotor_Di = getConst2(ParSim, 'Rotor_Di', d1);
Imp_inDia = d1;

if isfield(ParSim.operating, 'P_in')
    dp_req = ParSim.operating.P_in;
elseif isfield(ParSim.operating, 'dp_target_bar')
    dp_req = ParSim.operating.dp_target_bar;
elseif isfield(ParSim.operating, 'dp_target_Pa')
    dp_req = ParSim.operating.dp_target_Pa / 1e5;
else
    dp_req = getConst2(ParSim, 'P_in_default_bar', 1.0);
end

alphavolute = abs((atan(((d1/d2)/(pi*(d3_i/d2))) - (tan(deg2rad(alphaTH))/pi)) - deg2rad(0.05)) * 180 / pi);
%[text] Slip Loss - Eddy Circulation Model
e_limit = exp(-8.16 * sin(Beta2) / Z_LA);
if e_limit >= (d1 / d2)
    sigma_0 = 1 - (sqrt(sin(Beta2)) / (Z_LA^0.7));
else
    sigma_0 = 1 - (sqrt(sin(Beta2)) * (1 - (((d1/d2) - e_limit) / (1 - e_limit))^0.3333) / (Beta1 * (Z_LA^0.7)));
end
%[text] Volute Parameters
alpha_v = alphavolute;
yc = yc_i;
Cdl = cdl;
d_eye = deye;
d_th = d_eye;
Theta_throat = rad2deg(2 * atan((d_th - b3_i) * 0.5 / L_throat));
k_volute = k_volute_i;
k_impeller = k_impeller_i;
Nu_propellant = Nu;

u2 = pi * N * d2 * 0.001 / 60;     % Tip velocity (m/s)
Re2 = u2 * d2 * 0.001 * 0.5 / Nu_propellant;
dhv_d2 = 1 / ((0.5 / ((b2/b2)*(b2/d2))) + (1 / (8 * pi * (d3_i/d2) * sin(deg2rad(alpha_v)) / Z_LA)));
k_dhv = (k_volute / d2) / dhv_d2;
Lv_D2 = 0.5 * pi * d3_i / (d2 * cos(deg2rad(alpha_v)));
Cf_th = 0.5 + (2.6 * sin(deg2rad(0.5 * Theta_throat)));
epsilon2 = 1 - (Z_LA * e1 / (pi * d2));
%[text] Iteration Loop Setup
eta_v_ass = 1;
sigma = sigma_0;
sigma_iteration = sigma_0;
eta_vol_iteration = eta_v_ass;
x = 1;
x_iteration = sigma_0;

eta_vector = zeros(1, NPoints);
x_vector = zeros(1, NPoints);
sigma_vector = zeros(1, NPoints);
phi_vector = zeros(1, NPoints);

epsi_lower_limit = 0.002;
epsi_vector = linspace(epsi_lower_limit, 0.30, NPoints);

for j = 1:NPoints
    epsi = epsi_vector(j);
    for i = 1:NPoints
        phi = (-0.5 * epsi * (1/tan(Beta2))) + (0.5 * sqrt(((epsi * (1/tan(Beta2)))^2) + (2 / (sigma * x))));
        y = 1 + (epsi * (1/tan(Beta2)) / phi);
        
        sigma = max(1 - ((1 - sigma_0) / y), 0.01) * slipLossMulti;
        CH_0 = sigma * y;
        
        CV_5 = 4 * epsilon2 * eta_v_ass * epsi / ((d3_i/d2) * (b3_i/b2) * tan(deg2rad(alpha_v)));
        CV_4 = epsilon2 * eta_v_ass * epsi / ((d3_i/d2) * (b3_i/b2) * tan(deg2rad(alpha_v)));
        CV_eye = CV_5 / eta_v_ass;
        CV_3p = CV_4 / cos(deg2rad(alpha_v));
        CV_3d = sigma * (phi + (epsi * cot(Beta2))) - CV_4;
        CV_3r = epsilon2 * eta_v_ass * epsi / ((d3_i/d2) * (b3_i/b2));
        
        tmp_sqrt = (CH_0 - ((CV_4^2 - CV_5^2 + CV_eye^2) / (2 * phi^2)) - ((1 - (d1^2/d2^2)*(d_eye^2/d2^2)) / 8));
        tmp_sqrt = max(tmp_sqrt, 0.0001);
        eta_vol_calc = max(1 - ((yc/d_eye) * ((d_eye/d1)^2) * ((d1/d2)^2) * sqrt(2) * Cdl * phi * sqrt(tmp_sqrt) / (b2 * epsilon2 * epsi / d2)), 0.005);
        
        eta_v_ass = eta_vol_calc;
        eta_vol_iteration = [eta_vol_iteration, eta_v_ass]; %#ok<AGROW>
        sigma_iteration = [sigma_iteration, sigma]; %#ok<AGROW>
        
        Re_v = 2 * CV_3p * dhv_d2 * Re2 / phi;
        fv = 0.3086 / ((log10((6.9 / max(Re_v, eps)) + (((k_dhv)/3.7)^1.11)))^2);
        C_fv = fv * (Lv_D2) / dhv_d2;
        h_lv_ratio = (C_fv * (CV_3p^2)) + (Cdv * (CV_3d^2)) + (CV_3r^2) + (Cf_th * (CV_4^2));
        hl_eye_ratio = CV_eye^2;
        x = 1 / (1 + h_lv_ratio + hl_eye_ratio);
        x_iteration = [x_iteration, x]; %#ok<AGROW>
    end
    eta_vector(j) = eta_vol_calc;
    x_vector(j) = x;
    sigma_vector(j) = sigma;
    phi_vector(j) = phi;
end

if plt_option == 1
    figure; plot(sigma_iteration, 'bs'); title('Sigma Iteration');
    figure; plot(eta_vol_iteration, 'r*'); title('Volumetric Efficiency Iteration');
    figure; plot(x_iteration, 'mo'); title('X Iteration');
end
%[text] Head, Flow, and Pressure Curves
CH = x_vector .* sigma_vector .* (1 + (epsi_vector .* cot(Beta2) ./ phi_vector));
CH_inf = 1 + (epsi_vector .* cot(Beta2) ./ phi_vector);
H_inf = CH_inf .* (u2^2) / g;
H_actual = CH .* (u2^2) / g;
CQ = eta_vector .* epsilon2 * (pi^2) * (b2/d2) .* (epsi_vector ./ phi_vector);
Q_actual = CQ .* N * ((d2 * 0.001)^3) / 60;
Q_actual_lpm = Q_actual * 1000 * 60;
dP_actual = H_actual * rho * g / 1e5;

%% Power Losses Calculations
d2_small = d2 * epsilon2 * pi / Z_LA;
epsilon1 = 1 - (Z_LA * e1 / (pi * d1));
d1_small = d1 * epsilon1 * pi / Z_LA;

Wav = 2 * u2 * epsilon2 * (pi/Z_LA) * (b2/d2) .* epsi_vector ./ (phi_vector .* ((d1_small * b1 * b2 / (d2*b2*d2)) + (d2_small * b2 / (d2^2))));
D_hydraulic = 2 * ((d1_small * b1) + (d2_small * b2)) / (d1_small + b1 + d2_small + b2);
Re_impeller = 2 * Wav .* D_hydraulic * Re2 / (u2 * d2_small);
k_dhi = k_impeller / D_hydraulic;
f_impeller = 0.3086 ./ ((log10((6.9 ./ max(Re_impeller, eps)) + (((k_dhi)/3.7)^1.11))) .^ 2);
L_blade = 0.5 * d2 * (1 - (d1/d2)) / sin(0.5 * (Beta1 + Beta2));
C_h_lf = 4 * Cd_impeller * (L_blade / d2) * 0.5 .* ((Wav ./ u2) ./ (D_hydraulic / d2));

% Disc Friction Losses
G = y_gap / (0.5 * d2);
if Re2 < 4.5e4
    if G > 1.62 * (Re2^(-5/11))
        F_d_friction = 18.5 * (G^0.1) * (Re2^-0.5) / pi;
    else
        F_d_friction = 10 / (G * Re2);
    end
elseif Re2 >= 4.5e4 && Re2 < 1.6e5
    if G < 188 * (Re2^-0.9)
        F_d_friction = 10 / (G * Re2);
    else
        F_d_friction = 18.5 * (G^0.1) * (Re2^-0.5) / pi;
    end
else
    if G < 188 * (Re2^-0.9)
        F_d_friction = 10 / (G * Re2);
    elseif G > 0.402 * (Re2^(-3/16))
        F_d_friction = 0.51 * (G^0.1) * (Re2^-0.2) / pi;
    else
        F_d_friction = 0.4 * (G^(-1/6)) * (Re2^-0.25) / pi;
    end
end

K_d_disc = F_d_friction / (40 * epsilon2 * b2 / d2);
if eAx_option == 1
    rotor_loss_fraction = ((0.5 * drotor)^5 - (0.5 * di_stator)^5) / ((0.5 * d2)^5);
    C_h_disc = (1 + rotor_loss_fraction) * K_d_disc .* phi_vector ./ (eta_vector .* epsi_vector);
else
    C_h_disc = K_d_disc .* phi_vector ./ (eta_vector .* epsi_vector);
end
%[text] Inlet Shock Circulation Loss
C_h_circ_in = max(((1 - (epsilon1 * pi * sin(Beta1) / Z_LA)) * ((d1/d2)^2)) - ...
    (cot(pi - Beta1) .* epsi_vector ./ (b1 * epsilon1 .* phi_vector ./ (b2 * epsilon2))), 0);
%[text] Shaft Power and Hydraulic Efficiency
CH_0_vector = sigma_vector .* (1 + (epsi_vector .* cot(Beta2) ./ phi_vector));
C_h_leakage = ((1 ./ eta_vector) - 1) .* (CH_0_vector + C_h_lf + C_h_circ_in);
CH_shaft = CH_0_vector + C_h_lf + C_h_circ_in + C_h_leakage + C_h_disc;
Eta_Hydraulic_vector = CH ./ CH_shaft;
%[text] Operating Point Interpolation
Q_vec = Q_actual_lpm;
P_actual = dP_actual;
T_vector = P_actual .* Q_vec * 100 ./ (2 * pi * N .* Eta_Hydraulic_vector);

Imp_Pratio = 0.92;
Q_m3s = ParSim.operating.Q_in * 1e-3 / 60;
P_m = dp_req * 1e5 / (g * rho);
Nq = N * (Q_m3s^0.5) / (P_m^0.75);

Outer_dia = max(drotor, Motor_D_o);

% ==========================================================
% UNBREAKABLE INTERPOLATION BLOCK
% ==========================================================
try
    % 1. Strip any complex/imaginary math artifacts
    Q_real = real(Q_vec);
    Eta_real = real(Eta_Hydraulic_vector);
    T_real = real(T_vector);
    P_real = real(P_actual);
    
    % 2. Filter out NaN and Infinity
    valid = isfinite(Q_real) & isfinite(Eta_real) & isfinite(T_real) & isfinite(P_real);
    Q_valid = Q_real(valid);
    Eta_valid = Eta_real(valid);
    T_valid = T_real(valid);
    P_valid = P_real(valid);
    
    % 3. Filter out duplicate coordinates (which crash interp1)
    [Q_clean, unique_idx] = unique(Q_valid);
    Eta_clean = Eta_valid(unique_idx);
    T_clean = T_valid(unique_idx);
    P_clean = P_valid(unique_idx);
    
    % 4. Interpolate securely
    if length(Q_clean) >= 2
        pump_eff = interp1(Q_clean, Eta_clean, ParSim.operating.Q_in, 'linear', 'extrap');
        pump_trq = interp1(Q_clean, T_clean, ParSim.operating.Q_in, 'linear', 'extrap');
        pump_pressure = interp1(Q_clean, P_clean, ParSim.operating.Q_in, 'linear', 'extrap');
    else
        pump_eff = 0.01; % Give GA a 1% efficiency penalty
        pump_trq = 1.0;
        pump_pressure = 1.0;
    end
catch
    % If absolutely anything else fails mathematically, do not crash.
    pump_eff = 0.01; 
    pump_trq = 1.0;
    pump_pressure = 1.0;
end
% ==========================================================

Fax = 0.1 * pump_pressure * ((pi*(Outer_dia/2)^2 - pi*(Rotor_Di/2)^2) - Imp_Pratio * (pi*(Outer_dia/2)^2 - pi*(Imp_inDia/2)^2));

OutPump.efficiency = pump_eff;
OutPump.torque = pump_trq;
OutPump.pressure = pump_pressure;
OutPump.D_impeller = d2;
OutPump.F_axial = Fax;
OutPump.Nq = Nq;
OutPump.Q_vec = Q_vec;
OutPump.P_vec = P_actual;
OutPump.Torque_vec = T_vector;
OutPump.Eff_vec = Eta_Hydraulic_vector;
%[text] Cavitation / NPSH Check
p_suction_abs = ParSim.operating.p_suction_abs;
p_vapor = fluidProps.p_vapor;
NPSH_required = ParSim.operating.NPSH_required;

D_eye_m = deye * 0.001;
D_hub_m = getConst2(ParSim, 'D_hub', 0) * 0.001;
A_suction = max((pi/4) * (D_eye_m^2 - D_hub_m^2), eps);
v_suction = Q_m3s / A_suction;

NPSH_available = (p_suction_abs - p_vapor) / (rho * g) + (v_suction^2 / (2 * g));
NPSH_margin = NPSH_available - NPSH_required;
NPSH_ratio = NPSH_available / max(NPSH_required, eps);

OutPump.cavitation.p_suction_abs_Pa = p_suction_abs;
OutPump.cavitation.p_vapor_Pa = p_vapor;
OutPump.cavitation.v_suction_mps = v_suction;
OutPump.cavitation.NPSH_available_m = NPSH_available;
OutPump.cavitation.NPSH_required_m = NPSH_required;
OutPump.cavitation.NPSH_margin_m = NPSH_margin;
OutPump.cavitation.NPSH_ratio = NPSH_ratio;
OutPump.cavitation.cavitation_risk = NPSH_available <= NPSH_required;

if OutPump.cavitation.cavitation_risk
    OutPump.cavitation.status = 'FAIL: NPSH_available <= NPSH_required; Cavitation risk predicted.';
else
    OutPump.cavitation.status = 'PASS: NPSH_available > NPSH_required.';
end

OutPump.calculated_angles.Beta1_deg = ParSim.pump.Beta_1;
OutPump.calculated_angles.Beta2_deg = ParSim.pump.Beta_2;

end

%[text] Helper Functions
function props = getFluidProperties2(ParSim)
    if isfield(ParSim, 'fluid') && isfield(ParSim.fluid, 'name') && ~strcmp(ParSim.fluid.name, 'custom')
        try
            fluid = ParSim.fluid.name;
            T_K = ParSim.fluid.temperature_K;
            P_Pa = ParSim.fluid.pressure_Pa;
            
            props.rho = double(py.CoolProp.CoolProp.PropsSI('D', 'T', T_K, 'P', P_Pa, fluid));
            mu = double(py.CoolProp.CoolProp.PropsSI('V', 'T', T_K, 'P', P_Pa, fluid));
            props.nu = mu / props.rho;
            props.p_vapor = double(py.CoolProp.CoolProp.PropsSI('P', 'T', T_K, 'Q', 0, fluid));
            return;
        catch
            % Fallback
        end
    end
    
    props.rho = getConst2(ParSim, 'rho_propellant', 1200.0);
    props.nu = getConst2(ParSim, 'Nu', 5.0e-7);
    props.p_vapor = getConst2(ParSim, 'p_vapor_default', 1.0e5);
end

function value = getConst2(ParSim, name, defaultValue)
    if isfield(ParSim, 'constants') && isfield(ParSim.constants, name)
        value = ParSim.constants.(name);
    else
        value = defaultValue;
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":27.8}
%---
%[text:image:684e]
%   data: {"align":"baseline","height":461,"src":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOkAAAGKCAYAAADpIGajAAAA4WlDQ1BzUkdCAAAYlWNgYDzNAARMDgwMuXklRUHuTgoRkVEKDEggMbm4gAE3YGRg+HYNRDIwXNYNLGHlx6MWG+AsAloIpD8AsUg6mM3IAmInQdgSIHZ5SUEJkK0DYicXFIHYQBcz8BSFBDkD2T5AtkI6EjsJiZ2SWpwMZOcA2fEIv+XPZ2Cw+MLAwDwRIZY0jYFhezsDg8QdhJjKQgYG\/lYGhm2XEWKf\/cH+ZRQ7VJJaUQIS8dN3ZChILEoESzODAjQtjYHh03IGBt5IBgbhCwwMXNEQd4ABazEwoEkMJ0IAAHLYNoSjH0ezAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAgAElEQVR4nOydd3QUVf+Hn5ndhIRA6EgNoCCoSK+hIwgqhtBCV3zlJ6ggiCJgA19UUJDAK4ggSi+hozQFDCBIUZAqIDUUAQEhQCDZ3Zn7+2OzywZSNsnW5D7n5JxkdndmNsmz3zv3fuZeRQghkEgkPovq7ROQSCTpIyWVSHwcKalE4uNISSUSH0dKKpH4OFJSicTHkZJKJD6OlFQi8XGkpBKJjyMllUh8HCmpROLjSEklEh9HSiqR+DhSUonExzG6Y6fuuvtNURSPHEciyYj7\/xfdiVskdReapqFpOgaDiqrKRoAkd+A3\/+m6rjNnzjyefPhlNmzYxI0bN7x9ShKJR\/AbSYUQ7N+\/n\/MXbvO\/t4zMmTOL+Ph4b5+WROJ2\/ErSpKS7BLOT639W4fRJE9OmfS1FleR4\/EZSgFOnTnGdi7zG\/9jxZW8SE+8ya5asqJKcjd9IqmkaP\/30E0ajgbqfFacM2\/hlRhvi46\/z9deyokpyLn4hqRCCM2fOAKCjcKh8aWa0nIf5fDhn\/ypNUtJdKaokx+I3ku7YscP+\/Zm4s+Qd8yHvtPqMvxa8ghCQmJgoRZXkSPxCUl3X2bVrF2CVdOfu3eSpV4fwyldo0PA8Gz\/qiqIIKaokR+IXkgKcPn0asEp66eJFAPK9PYB3a4ynKI9zaFtVKaokR+IXkto6jcAq6e7duwEwlimDGmBk3E9nObvxOeL\/DUFRZNNXkrNwu6S6rmMymVJsM5vNWCwWp14vhLBXUUfOnz+PYjCQ980BFF0RTY+RebkU8w5BQUGAFFWSc3CrpNYo3xyCgoLsgWSz2UxERARRUVFOhZSFEPbrUUVR7F+7d+8GRcFYtiyGsFL0bRxLnlKgXxpO3rx5ACmqJGfg9kqqqioGg8H+s6IoGI1G8uXL5\/Q+AgMD6dSpEw0bNqRRo0Z06tSJ8uXL2w5A\/qFDME2YzMilsH4itG\/fgUKFCgFSVIn\/47VrUmdvM1NVlR49erB06VIGDhzI4MGDWbBgAbVq1Uqxj8AXu1Hk14W8MRfeqVKFPn1elE1fSY7ALzqOhBBomoau62iaZt9mR1XJ26kDlkXLiOwBhavDZwML8tpr\/aWoEr\/H7ZIqipJCKCEEuq6TmJiY4nm6rmfvQKpK0NsDSZgQzYw\/4Ne5cOxAQV59VYoq8W\/cKqmiKJQsWdIe67NYLFy5coUDBw6kuGnbZDIxc+bM7N3trigENWmMOHse7cwZRv8EbzeBAgUK0L+\/FFXiv7hd0po1axIaGkqzZs3o2LEjzz33HJUrV7Y\/5+rVqwwZMoS1a9e64oDkHTKQO+MnEt4aGr8IfaoqFCwoRZX4L25v7hYpUoTdu3fTuXNnHn\/8cZYtW0bbtm1p0aIFANeuXWPgwIGuma9IUTCWKYNiNKKfOcN\/v4P4w7B0lhRV4r8owg2zed2\/y7SasUIIFEXBbDbTpUsXVq5cmaasuq4TExOD0WgkKioqbamFwHL2LAnjJ1FgcjRxJ+HFijD3FIRVENy4Ec\/XX39tvyYOCgqif\/\/+FChQIOtvWJLr8OREZB7p3RVCpPrl+JjLSA44qGVKkfTrr5StAB0+gA+ftz4sr1El\/obPDMG4dPa\/5IDD3U++QFVh4EiBYoQpHysoihRV4l\/4hKSqqtKoUSOX7zfwhW4kzF+IalAYuRSWfABxp6SoEv\/CJyQ1GAy89dZbrm32JgcczAuXARD2sGDgLHjjkXtPkaJK\/AGfkBTcNBt9csDh1vhoFFUhspegcHUY0ctaTUGKKvF9fEZSt+AQcLCcOYNqUJixR7BjPvyyUYoq8Q9ytqRgDzgkjJto+5HPt8L7rVM+TYoq8VVyhaS2gIPlzBkUVaF2uLCnkRyHu6SoEl8k50sK1k6kNweQMH6S7Uf++62wp5GkqBJfJndI6hhw2P4rKAqqCtEn4MuX4OxpKarEd8kdksK9gMOnX9g3lS0vUqSRHHG3qEIIrly5ItdYlWRI7pE0GVvAwVZN708jOeIuUXVd548\/\/qBmzZqsWrUqW\/uS5Hxyl6T3BRySNz2QRnLE1aIKITh69Cjt2rXj8ccfp3fv3kybNi3Lb0mS88ldkkKKgIPNyNTSSI64SlQhBBcvXuS5556jVq1abNiwgdWrVzN8+HA+++wzj95ZIfEfcp+k9wUcUKzVM7U0kiPZFVUIwaVLl2jZsiVlypRh2bJlCCFo1qwZ69evZ8yYMWzdulWKKnmA3CcpPBBwAGuzN7U0kiPZEfXSpUtERkaiaRp\/\/fUX+\/btsz9Wt25dunTpwqxZs7L91iQ5j1wrqWPAwWZkWmkkR7Ii6t27d4mMjMRsNvP777\/z7rvv0qJFCzZv3oymady9e5fY2FjKlStnf43L77OV+C25U1J4IOAAVknTSiM5khlRTSYTERERXLp0iZ9++omCBQsyaNAgoqOjadmyJc888wwNGzYkT5489OvXD7CufbNhwwbi4uJk81eSiyVNJeAA6aeRHHFGVCEEW7ZsYceOHQwbNoxixYrZq+Mrr7zCK6+8Qv78+Rk\/fjx\/\/vknJUqUwGKxsH79eqKiolI0iSW5l9wrKTjM4DD+\/s1pppEcyUhURVFo3bo18+fP5\/3332fq1Kn21+q6zhNPPEF8fDxt2rSxTwC+efNmevTowRdffEGHDh1kk1eSyyUFEAJDs\/AU1RTSTyM54kxFjYyMZPny5QwZMoRJkyZhsVg4c+YM06ZNo1q1asC9gEOHDh2YMGECffv2lYJKACkpGAzkf\/vNFHFBIMM0kiMZiSqEoHnz5sTGxhIdHU3hwoWpVKkSJUqUYOTIkei6ztGjR2nTpg3Dhg2jb9++6Lqe\/Vn9JTkCKSlYx06HvsGtcRNSVNOM0kiOOFNRGzRoQFxcHDNnziQ2NpZNmzYRGhrKkSNHiIiIoH\/\/\/rz\/\/vvous65c+f47rvvuHDhgpQ1lyMlBaukjRuhbd0B9zUxM0ojOeJMRRVC0LlzZ5o3b46u61y6dInOnTvTtm1bPvnkE\/u1ad++fVm4cCFNmzZl\/Pjx6R1WksORktpQVfJ9OY741wenqKbOpJEccbbXVwjBtWvXeO6553jssceYMmWKfa0cXdfZsGEDP\/\/8M3v37mXt2rWMHTtWDsfkUqSkNmwBh4CAFAEHcC6N5Iiz46iFChWiXbt2LF++HIvFwtixYylVqhSFCxdmyJAh\/Pvvv+TPn5+PP\/6Yjz76yNXvWOInSEkdSSXgYMOZNJIjzohqMBgYPXq0vaqOGjWKFStWEBcXR0JCAq1atWLHjh1s3LiREiVKuOQtSvwPKakjaQQckh9yKo3kiLNNX+v+FYKCgmjQoAFFixZl2rRpjBs3jk6dOhEdHc2SJUvQdR2z2YzJZMJisaQ4luxcyrlISe8njYBD8kNOpZEccbbpW7hwYYYOHUpUVBSXLl0iMTGRM2fOcOfOHZYvX06tWrWYOXMmNWrUoFChQvTr148bN26gKAomk4kpU6Zw69Ytl\/wKJL6FlDQ10gg4gPNpJEecbfqOHDmSfv360bt3b0qVKkW\/fv2YOnUqLVu2ZNCgQbzzzjuMGjWK48ePU7x4cfr06YOmabz33nuMHj2a27dvy86lHIhHlj50BU4vfei6A3IjIoqCa5Y9MCyj6\/DlRwr7lsOsQ+L+h9MkPj7jZRcVRUEIwbPPPkvLli0ZOnQo3377Le+88w779u2jbNmygDWEX716dZ5\/\/nlmzJjB3r17KVu2rEwpeYgct\/ShX5JGwAEyl0ZyJDPDMx9\/\/DFDhw4lKSmJL774gqlTp9olFEJgNptJSEjg22+\/5ddff5WC5mCkpGmRTsABMpdGcsQZURVFoXbt2nYhjxw5QuPGje2Pa5rG0qVLuX37NmvWrKFSpUqy4ygHIyVNjzQCDjYyk0ZyJDO9vqqqEh4eztatW9E0DZPJxObNm3n77bdZvnw5devWJSkpiePHj3P+\/PkHen0l\/o+UND3SCTgkP5ypNJIjzvb6Go1Gxo8fz\/Dhw3nttdeIiIigffv2zJs3jyZNmrBt2zYqV65MzZo1qV+\/Pu3bt5eTeOcwpKQZkU7AIfnhTKWRHHG26duwYUMOHjxIvXr12LZtG9OmTaNVq1Zs3LiR5s2b07p1a\/7991\/+\/vtvmjRpQkREhOzlzUFISTMinYCDw1MylUZyxNmmb758+ejUqRNz586lV69eJCYm0qtXL\/7zn\/+wefNm1q9fjxCCoUOHcuzYMS5cuCBFzSFISZ0hnYADZC2N5IizTd8CBQrQsWNHdF1n586dmEwmpk+fzpIlSxg8eDDTpk3DbDajKIoUNAchJXWWdAIOkLU0kiPOimrr8b19+7Y9z1ujRg02b95MdHQ07dq1o2TJkpQqVUoOyeQQpKTOksYMDo5kJY3kiLOiqqpKmzZtiI+PJzY2FovFQqlSpYiNjUVRFGbPnp3ptyfxXaSkmSGdgIMNZ+dGSgtnRTUYDCxbtoxu3brRsWNHmjZtyrp169i4cSPVqlWTVTQHISXNDBkEHCDraSRHnO31bdCgASdOnKBdu3b069ePtm3bAu6JZUq8h8zuZhYhsJw9S8Ln0RT4alKassadVOhTCWafhHIPO5\/vdcSZrC+kzJFKQT2DzO76MhkEHHRdR9MslCxrot90LdNpJEcy25kkBc2ZSEmzQioBB7PZzN27d5k9ezavvz6A+vXr8fao8jwUnvk0kiPuXnFc4vtISbOCY8Dh1x1YNI2IiAhCQkJ4+eWXmT59OvHx8ezbt5evfyFLaSRHpKi5GylpVrEFHD4eh2Iw0KtXL\/tDwcHBLFmyhGLFigEiy2kkR6SouRcpaXYQAhrX56958zEYjURGRhIYGMjixYupU6cOQohsp5EckaLmTqSkWUTXdSxC8GP5suj\/m073bt2YNGkSixYtol27dik6cbKbRnJEipr7kEMwyft27B01Go3pPlfXdZYsWWI\/l8QtWzFt3UboB+8Cab\/\/uFMKL1aEuacgrELWhmVsODs8I3EPnhyCyfWSWiwWVq5cya1bt1i\/fj2KojB9+nRCQ0MzPAdIfq+axo2OPSi4KiaD95C1uZHSIi1RQ0NDZcDezchxUg+h6zoLFizg+vXr\/Oc\/\/2HRokVcv36diRMnpvpHUFWVHj162D8k7B8Uqkq+\/32e5gwO916f\/TSSI6k1faOjozlw4ED2dizxKXK1pLa5goKDgwFrVYyMjOTcuXNpvibV0EAGAQdHsjo3UlrYRA0ODrbforZy5Ur279+fvR1LfIZcLamqqrRs2ZKNGzcC1qZvUlISUVFRmZ8rKIMZHBzJ6txIaVGwYEGGDRtG5cqV7dukqDkHv5dUCJEpoYQQKRbobd26NatWreLGjRt8+umnPPzww0yYMIGePXty8+bNFK9Nd0Y+J2ZwcHhqludGSus9CSHo2rUrVapUsW+XouYM\/FZSXdcxmUwcPXqUwYMHp3oNaZPR9qVpGqdOnWLx4sUsWbKEFStW8Nhjj\/HYY4\/x448\/8tFHH9G+fXvWrl3LkSNHGDlypH2\/FouF7777Lv0OgwxmcLjvqVmeGyk9pKg5D7\/q3V24cCFGo5EOHTqwceNGhg8fzqFDhzAajZjNZjRNS\/H8rVu3cuXKFfs2RVEoVaoUTZo0sW+zWCxMnjyZ2NhYVq1aZa+0MTExDBkyhEuXLqFpGj\/88AP\/\/e9\/2bt3b\/rvT9O49cVEAhuHk6dReJp3yYD1od+3KwxtCltE9nt7HYmJieHo0aP2nyMjI6levbrrDpDLkUMwqWCxWHjzzTc5e\/Ysv\/76K9euXbMvyWAwGPj0008pV67cA\/PVlilTJsPzu3DhApUqVeKff\/4hf\/786LrOyZMneeaZZzhx4gQWi4Vx48ZRoEABatasScOGDdN\/j+ksUZHKU\/nwZYULv7tmWMYRKar78KSkhlGjRo3y2NGyya1bt6hRowbPP\/88YWFhlCxZkuPHjxMYGMgrr7xC586dqVq1KlWrVuWJJ54gNDTUqQ+MvHnzsmPHDpKSkqhTpw6aprFv3z5KlChBkyZNUBSFJk2aULFiRb755htat3YiiFumJHeXLLdW03RQFGgeAXMHKhjLKzxR09nfRsZUrVqVy5cvc\/XqVQCOHj1KoUKF5FqnLsCTkqYdrfFBbMJ17tyZzp0727dv376dsLCwFM\/JDKqq0rt3b4YNG0bRokXRNA2LxcKIESPs+7NNq+nU8oLJMzgkfjEZhjpzfOvcSC9WhHrNlGynkRzp2rVrioq6cuVKAFlR\/Qi\/ae6mlziyfapl57jXrl0jLCyM48ePU7p06VT3p+s6y5YtIygoiIiIiPSPJwSJW3\/B\/Pte8r\/9plPNXlemke5HNn1di0wcZRJXzEpQoEAB2rRpw9KlS+37vB9VVYmKispYULBW0yaNEWfPZxhwsO7btWmk+5G9vv5LjpDUFaiqytNPP81vv\/2W7vMy9YGgKOQdMpCEcROdPAfXppHup2vXrlSuXNl+\/lJU\/0BKmoyiKISHh9O9e3dX7vReXPD06QyrKbg+jWRDCEFSUhKFCxfm5s2b9uaaFNX3yRHXpK7CFde2qSIEN57rRMF1KzK8NgXr9Wnf2golqsKYedm7PhVCYDKZ2LRpEyNGjODatWv8\/vvvbNmyhT\/\/\/BNVtX5Oy2vUzCGvSb2E22bc03UMzRtlGBe04ao0kq7rrFu3jrp169KuXTuOHDnCiBEjKFmyJPXr108Re5QV1XeRknoCJ5aouJ\/srNQG1g+ckydP0rt3bw4dOoSiKDRr1owBAwYghKB8+fIMHjyYGzdu2F8jRfVNpKSewoklKu57erbmRlIUhYcffpjJkycDkCdPHhYuXJjiOeXKlZOi+gFSUk\/huESFk2RnbiRN09i6dSsVK1ZkyZIlDBo0iGLFij3QnJei+j6y48iTZDLgYCOzcyNZLBa2bdtGxYoVKVu2rMPh035hXFwcEydOpGDBgvZtsjMpbWTHUU4lkwEHG86u1CaEwGw2s2zZMipVqkTZsmWdXoJCVlTfRUrqaTIZcADn0ki6rnPq1ClWrFhBt27dKFOmTKZbGzZR4+Pj5TiqDyEl9TRZCDhA+mkki8XCli1b+Pfff+natWu2hpLKly9PdHS0nIrFh5CSegODgdAJn3H7tSGZetn9aSTH5u2jjz5KvXr1sn2tLqdi8T2kpN4ikwEHuG9upN4KcXGns9W8zQgpqm8gJfUWWQg4gLXZO\/03je3zYM+vebLdvM0IKar3kZJ6k0wGHHRdx2IxW8c9519gcq8ygPuHoqSo3kVK6k2cDDjYpi3dvHkzK1aspEePbnToVppGLlipzVmkqN5DSuptVJWgtwZwa3x0qtXUNg3psmXLqFy5sj3IoSjCZSu1OYsU1TtISb1NGgEHa9PWwpIlS7h48WKqnUO2uZG+fAnOnpai5lSkpL6AQ8BBgEPTdgXdu3enSZMmaXYOOZtGciVSVM\/iM5IKIeyz9NkmuvbLfG5WSA446KrKiU2bWLZ8eYqmbXq\/B3fPjZQWUlTP4RNTegohOHfuHEuXLuWff\/7hr7\/+Ijw8nFatWlGjRg1vn57b0XUdTQh+Cq9L2+ipdFud9mRoqWFLI\/WpBO16KJR72PWzDaaGnC7UM\/iEpJqmMXr0aMaNG0ehQoUAuH79OsOHD+e9996zz6mb00ixanhAAN26d+fm2Qskbv81w0m178eaRlJ44xFY5cEGiBTV\/fhMczchIYFChQqhaRqaphESEkL9+vU5duyYt0\/N5dg6hWJiYlixYoV1YeIuXRBCZCngAK5fqS0zyKave\/GJ+0k1TeOLL75ACGFfz+XGjRv88ccfTJw4kbx58+aM+0mxCrplyxauXr1KVFQUcN\/vy3bP6W97yD90iNP3nN7bPzxlVBi9AZq08kyz10ZumoA7Vy7YpCgKFy9eZM+ePdy6dYuGDRvahVUUxackta28Zjs3g8GQqddnOCuhpnGjQ3cK\/rAk05K6c6U2Z8gtouZKSYUQ\/Pzzz0yePJm8efNy9+5dAN577z37Ikq+IKmtk2v16tX89ddfBAUFMXz48BQzGrjgIFmawcGGO1dqc4bcIGqulBQefOPTpk2jQ4cOFC9e3CcktQn64YcfMnv2bHRdJzIyksKFCzNr1izXnpOuc\/PNd8g7ZCDG8uWzJGpno0LPmdC5jxTV1eTa6VM0TcNkMmE2m0lMTCQhIcGnOiB0XeeHH37giSeesG8bPHgwBw4ccHof7lqi4n68kUZyRHYmuQ6fkVQIQWxsLJ07d6Z379706NGD4OBgWrdu7TOdRIqiUKhQIdasWQNYpa1UqRLNmzfP8Bw1TcNsNnP69GmuXbvmzMGyNIODI95IIzkiRXUNXmnuJiUlYTAYUFXVvswBpN6EsO3Lmx1Huq7bv79+\/TphYWGcPn2aNWvWEBcXx\/nz58mXLx+jRo1KcW1q61j6999\/GTduHHFxcVSvXp0tW7awZMkSQkJCMj54JpeoePDcrUtW1OkMr7\/v+WYv5Mymb45eRNhkMhESEkKXLl14+umniYiIIDQ01C6sJ998WjhKaQsbqKqKwWCgY8eOtG\/fnu+++44RI0bYn9O2bVu6devGjz\/+aI\/y7dmzh7p16xIaGsrRo0dZuXIlFouFPHnycOXKFfLly5fxh43DDA55GoVnWlRvpZEckYGH7OHxSqrrOmvWrGHdunWsW7eOuLg4GjRoQEREBK1bt6ZGjRqpDmmkVUltmV+jMWufN45C2n62SQn31iS1oWkaq1atYsSIERw7dsx+HqdPn+aRRx7h3LlzlClThjt37lCzZk1+\/\/13goOD+fDDD2nYsCG7du3ijz\/+oEqVKnz44YeEhoY6c5LciIii4JplWaqmQsCKuQpz+sAqLwzL2MhJFTXH9+46vsEjR46wceNGFixYwM6dO3n55ZeZMWNGqqtsO0pqC+OfPHmSKVOmMGXKlDSPe7+IjtsdhYQHpUzt\/VgsFsLCwli1apV98i+z2Uy9evX46quvqF+\/PmPHjqVQoUIEBwfz0ksv8eeff9KtWzcWL15MlSpVWL58Of\/88w\/9+\/d3qpreWbocYbEQ0rN7tpq9rlipLTvkFFFzdHNXCMHly5c5cuQIu3fv5rfffuPgwYOcPn2ahg0b8uSTT6b7el3XSUpKYuPGjQwfPpxDhw5hNBqZMmVKqjLqus7WrVu5cuXKA4+pqkqPHj1SPceM6NatG\/Pnz6devXrWgLymkS9fPsLDwxFC8MYbb5A3b1569OjBSy+9RKVKlahUqRJVqlQhMTGRo0ePpuhUSRdVJW+nDtyI7AY9s7Z+qm2ltqeMCr\/0UTyeRrJha\/oeOXIERVFk09cJvHJNWrJkSQDat29Py5YtGTx4MI0bN7Y\/J72KuHDhQgYMGMC1a9dSJHc+\/\/xze0LJEVVVCQ8P56mnnkp1n1lpSBgMBnr16kXz5s154oknyJ8\/P\/\/88w9ffvml\/Tn58uVD0zQqVqzImTNnCAsL4\/nnn6d3795omsbzzz9Px44dnT++qhL09kBujY\/OUsAB7q3UZk0jZfrlLkEIQYcOHThx4oT9dkQpavp4vLlrsViIiori0KFD3Lhxg2rVqlGtWjWefPJJmjZtSvny5TO8JlVVlZ07d3LmzBlWrVpFQEAACxYsIDIyMkvnlBUsFgv16tXj3XffpUWLFhQtWvSB4wghOHv2LF9\/\/TVjx44lPj6ec+fOUbVq1aydUzYDDsm78EoayXEx4\/fee49HH33U\/n9gw5+avrnmmvSff\/5h+\/bt7Nmzh02bNrFz50569uzJvHnzMrwmdWT79u2EhYXZ1z7xBJqmMXnyZGJjY1m1alWaxxVCsH37dvvsCoqiZP0chcBy9iwJ4yZSYMrELEkKnk8jmUymFJcn5cuX5\/Tp0wgh\/PYaNccnjmyJosOHD3Pw4EG2bNnCwYMHqVmzJq1bO7dqruNCRI0aNfKooGBtRrdr144NGzak+zxFUeyCQjYrui3gYDRmasGn+\/FkGslisRAZGUm7du04dOgQgYGBKS4LZOAhYzwuqcVioVOnTpQpU4ZWrVqxfft2evbsyeHDh9m7dy8vvvhipv+R3Tk5dFooikK5cuVo1aoVV69eTfeT1aXnpqrkfXMACeMnZWs3rk4j2aYdvR+j0WiXUlVVunTpQrt27VL8TqSo6eOVSpo\/f36+\/fZbEhIS+PHHH+nfv7+908dXIoDOYDQa+f777ylSpIjnzltRMJYti1qmVKaWqLgfV86NJITg1KlTvPnmmw98WGmaRlxcHGPHjiUwMJAJEyakug8patp45ZrUJqOqqpjNZhRFyTCM4Ev3k\/oE2Qw42Ig7qdCnEsw+SbbSSBcuXKBPnz7MmjWLUqVKoSgKmqbxyy+\/2Bcz\/vvvvylVqlS6fzt\/uUbN0dekZrOZZ599ls6dOwMQERFBVFSUT8QB\/Y3AF7qRMH9hlqspPLhSW1YpU6YMGzduJDg4mGXLliGEYNu2bVStWtXeX5CRoCAramp4XFJb1bTlVm3fSzJJcsDBvHBZtnbjqrmRbLNVHD58mL59+\/LTTz\/RvHlzihUrlulOMylqSnziVrVc33TNKg4Bh+xUU1saacd8+GVj9q5Pw8PD+eijj+jWrRv79u3L8n6kqPfwCUklWSSNJSqyuCs+3wrvOzcC9gC6rnP69Gm2b9\/O4MGD6d+\/P5GRkVy6dCnL5yRFtSIl9XeyOYODw26oHS5onIWV2nRd58yZM1y4cIFmzZohhODTTz+lRo0aREZGcvPmzSyflxTVS5IqimLvKFIUJcVdKJJM4qKAA1ibvc6s1GY2m+2XKBaLhS1btnDt2jWaNm1q364oCjNnzgSgf\/\/+2eoYzO2ieqXjqEmTJjRs2DDF95Js4IKAg6ZpXLlyBUUR6aaR7t69S\/369Tl37hwWi4Vly5bx6KOP2m\/Zc6RgwYIsWrSI27dvZxj4yIjcLKph1KhRozx5QFVVady4MXXr1gWwf+\/M2Orhw4dRVVIedC4AACAASURBVDXFRGASQFFQQ0MxHzpkrayZWJZDCEFSUhJffvklnTp14qmnWvL4E2W4KWDhhxD52r3nmkwmBg4cyLp16zh16hQBAQF07dqV0NDQNP9+hQoVss9XlV2qVq3K5cuXuXr1KgBHjx6lUKFClChRItv7ziw5epwUUsb4bN+bzeYUX7bV1WTPr5OoKvmHDsnUEhUWi4UdO3bQoEEDxowZQ9u2benT56VU00iapjF37ly+\/fZbAFavXs358+eB9HvnXZ0iy40V1ScuBs1mMy1atKBWrVp07dqVrl270rt3b7p3787evXtl0CETOBNwEEJw9+5dRowYQbNmzahatSqnT59m0aJFBAUFMXLkSAwGhZFLYckHEHdK4fjxv3jrrbdQVZWAgADKlStH3rx5PfjO7pHbRPWpybF79+7NvHnzUt2fjAU6iaZxI7IbBVcvTTUuaDab+emnnxgwYAC3bt2iaNGi9kWxdF1n165dtGzZkn379vHoo5VZMRe+fRF49hk2bYrlrbfeon379tSrVw\/w7hi3NyOEOb65mxpCCEaOHMn169ftK6tpmpbm\/ESSNEgn4HDp0iVefvllIiIi6NSpE8eOHcNgMDBmzBjA+o9Xr149+vfvzyuvvIKiQPuegmLVQDs8ksTERD755BN7J5G3PyhzS0X1GUnBOi3J2rVriYmJsX+dP39eNnczQxoBB7PZTK9evThw4AC7du3iiy++oHDhwkyZMoXPPvuMY8eO2YfDPvjgA+7cucPJkycxGBS+3StIjGvALxsBvC+nI7lBVJ+S1JbrNRqN9rv5paBZIJWAg9FoZM6cOezfv9\/em64oCk2bNqV79+4MHjzY\/tzChQvz22+\/Ua5cueS7lLKXRnI3OV1Un5HUdhN1p06d6NSpEz169KBx48YprjkkTpJKwEFRFEqXLv1AM1VVVcaMGUOZMmW4ffs2YO3J\/fvvv+nbty99+vRBVZUsp5E8RU4W1WcktS192LFjR3r27ElUVBS7du2yT5EpySSpBBzS+j0WKFCAb775hpCQEJKSkpg5cyb16tXj0qVLfPDBB7bdOZVG8iY5VVSv9O7qup5qFNBX14LxW3SdW+MmENikUYZLVGiaxrFjxxgyZAh79uxh6tSpdOnSBUj594w7pfBiRZh7CsIqeG+S7fTwRK9vju7d1XWdZcuW2QMLthWzIeXkYr7Qe+j3OBFwEEKQmJjIpEmTaNiwIaVLl+bUqVN06dIl1b+Bt1dqc4a0Kqq\/9m94ZSKynj17UqBAAbp06cK0adM4deoUFovFPlmyxLWkFXDQNI0dO3YQHh7OtGnTWLNmDd999x158+bFZDKlOrGYK+dGcif3i7pq1aps3Y3jTTwuaWBgIGazme+\/\/57HHnuM6dOnU6lSJWrXrs1\/\/\/tfv\/7E80nSmMFBCMGvv\/5Ky5YtefbZZzl48CDh4eHs3buXAQMG8NxzzzF06FD+\/vvv1HaZIo3kq38um6i2UYP4+Hj\/\/N8SbkDX9XS\/LBaL\/ctsNouffvpJNGrUSCiKIrp06ZLqPiwWi5g\/f76IiYlx6hjyy+FL08Sd2M0iftwEod\/3u9uzZ48QQoikpCQxevRoERgYKKKiosTkyZPFoEGDRMGCBcXly5cf+J1rmi6WzhIiAiGE8IH3mMaXEELExcWJc+fOufT\/xpN4fC0YTdOYPn06+\/fv5+DBg+zdu5eiRYtSp04doqOj7XEziQtJDjiYln+P5cyZFEtU1KpVC03T+Oabb5gwYQKbNm2yr8sjhCA4OJhPPvmESZMm3b9LInsJVkcrjOileHWltvQQQhCWfFeQ8MUTdAZ3mJ\/eJ1BiYqIAhMFgEH379hUHDhzI8DW6Litptr80TZhOnxbXXxv0QDVNSkoStWrVeuB3q2ma2Lp1q2jQoEGav3OLRRfNEGLrBiF8uaK6+suTeLySGo1GFi9ezP79+9m+fTv169enePHiVK5cmaeffpqGDRvKsVF3cF\/A4f4FnzRNIzw8PMVLzGYzS5cutVciPZWhM19YqS2n4\/GOI9tSAx9\/\/DGxsbHcvn2b6dOnYzAYePvttx9oVklcSBozOCiKQq1atZg7d659rdXExETGjRvH\/Pnzee+99zCbzaxdu\/aBjpfszI0kcQ6PV1KwTsGxbt06tm7dyoYNGzhy5Ah169blo48+sg+gS9zAfUtU2AIORqORjz\/+mBYtWrBv3z4eeeQRYmJiuH37NitXruTxxx9nxIgR7Ny5k+eff3CA1JZG6mxUWDpL8chKbbkJjyeOTCYTwcHBhISE0LJlSzp27EibNm1STIGR2ut1mThyHbrOjee7UHDt8hRN3lu3bvHVV1\/x+++\/07p1a1588UWMRiNjx45l2rRp7Nmzh+LFi6f5u\/eHNJKr8ORQjleuSVevXs2zzz6bYruUzoMIgaFZeIpqCtaFtIYPH25\/msViYeXKlURHR7Nz506KFy9uT4kFBAQ8sFtrGknhw+dh1qEHHpZkEa9ckz777LMy\/udNDAbyv\/1mqnFB299D0zQ2b97MgAED2LRpE+XLl+fo0aOMHj2ap556imvXrj1QTfwljeRv+NT0Kekhm7suRggSt\/6C+bc95B86JEWzVwjBsWPHCA8P59133yU+Pp7vv\/\/evlLa1atX+fXXX3n44YdT\/Tu4aqU2XyZHB+wlPoKiENS4EdrWHQ\/cHaPrOnPnzuXWrVssWbKEIkWKsGLFCkaPHk18fDy\/\/PJLmoKC61Zqk1iRlTQ3IwSWs2dJ+DyaAl9NeqAT6fbt2\/blCteuXcuAAQNYvHgxderUsV+bGgwGDAbDA7vWdehbW6FEVXw2jZQdZCWVeAZbwCEg4IElKvLnz0+pUqXQNI3t27fTp08f5s+fT7ly5Zg9ezZdu3alfPnyfP7556n+w7pypbbcjpQ0t5POEhW6rnPo0CFat25NtWrVGDFiBOXLl2f58uU8\/fTT\/PHHH7z77rtptmp8fW4kf8ErYQaJD5FGwMH6kEKRIkWoXbs2TZo0oW3btjRo0CDFy9O77LiXRlLoU1Vh1qGc1+z1BPKaVGIljYDD\/U3ZrPzedR06GxV6ziTHpJHkNanE8zgEHBwvIF0xnq2qpLtSmyR9pKQSK+kEHFyBP8yN5KtISSX3UBSChr7BrXETsrUYcWrINFLWkZJK7pFOwMEV+MvcSL6GlFSSElUl35fjiH99sMurKcg0UlaQkkpSkk7AwUW7J7KXoHB1GNFLVlNnkJJKHiSdgIOLdi\/TSJlASip5kPsCDu6wSKaRnEdKKkkd2xIVn4x3y+7l3EjOIyWVpE0aAQdX4Q8rtfkCUlJJ2rg54AAyjeQMUlJJ+rgx4GBDppHSR0oqSR83BxxAppEyQkoqyRg3BxySDyHTSGkgJZVkjJsDDjZkGil1pKQS53BzwAFkGiktpKQS5\/BAwAFkGik1pKQS53FzwMGGTCOlREoqyRxuDjiATCPdj5RUkjk8EHAAmUZyREoqyTweCDiATCPZkJJKMo8HAg42ZBpJSirJKh4IOCQfJtenkaSkkqzhoYADyDSSlFSSdTwQcLCRm9NIUlJJ1vFQwCH5ULk2jSQllWQPDwUckg+VK9NIUlJJ9vFAwMFGbkwjSUkl2cdDAQfInWkkKanENXgo4AC5L40kJZW4BseAgwfITWkkKanEdagqQW8N4Nb4aLdXU8g9aSQpqcR1KApBTRojzp53e8ABck8aSUoqcS2KQt4hA0kYN9Ejh8sNaSQpqcS1OMYFT5\/2SLM3p6eRpKQS12MwEDrhM26\/NsQjh8vpaSQpqcQ96DqG5o08EnCArKeRTCbQ9Xs\/63ra27yFlFTiHjwYcLCR2TSSyQStgxS+X2CVWtdh+RyF5kEKP628t23BNIWng7xXoaWkEvfhwYBD8uEylUYyGKDxC7B+uvVnXYedq8EAxC6xbtM0WD8WnnrVraeeLlJSifvwcMABMpdGUlWI+A8c2mb9Wddhz3LoMBz2xFi3\/XtV4cw56NDX\/eee5nl679CSXIGHAw7Jh3QqjWSrvEFYm7lnTylYgFeGQyJw\/IjCpu8hFHiylnD3TDFpIiWVuBcPBxxsOJtGUhRo2h\/WfgXrF8Mjj0G+UEH5svDjEvj5O2j+VsrXOHYqeQIpqcT9eDjgAM6nkVQVol6Fv3bBniXQ7P+s2xv1gy0j4dhv8NLb955vMsH8qZ7tQZKSStyPFwIO4FwaSVGg4mOCEOD4YWjX3bq9eTs4D5QCipewNnWvXVH44EWFzd955PTtSEkl6ZNa287ZbY54OOBgw5k0kqrCgMXQsJNVSIBHnxDUj4AXF1ufIwT8ewX6fgBCNnclPoOukzB\/IfqNG\/ZN2tWrJMxb8OC2+QszrpAeDjiAc2kkVYXnugjGL73XOWQwwMRVgue6WLcpilXcCo8KKanEdxCahmlUNHdmzbX+l2oad2bPw9TnTe7MnmffljBpMqaxkzPeoRcCDuBcGkmIB+f5vn9bas\/xBFJSSZooqoqxbxSWxd8DIIRA+\/kXKPoQlk1brds0DW3ZegIG\/sfJnXo24OBwWJfNjaQas7+PTB3Ps4eT+BUGA8Ev9ETs3Ifl3DnQNMS6Xwle+CVitTUBYDl1Co6eIm+Prs6VGS8EHJIP65K5kVQVakW69twyPKZnDyfxNwwPPYQSXpO7c+aTtGs3FC1CUKuWEFqQxJ83k7hoCUrzuqgFCji\/Uy8EHJIPm+25kQwGGPChZ9u8UlJJuiiqSsDLPbGsXI\/pp42o7ZuCrqO0roVpwyYsK34ksF8f65M1DWGxICyWDHbqnYADuGZuJE9fl0pJJemjqgRFtIPf\/0Kbs4qAds+AohDQoR3a2PlwMI7gyAiwWLg1+lPiu\/fh5sAh6Ddvpr9fLwQcbPjb3EhSUkmGqAUKoDzTAM7\/Q1DzpgDkadYEuIkS1QIlKAjLxYsQHEzBpfPJ++YA7sxdkH6FTC3g4KG8nb\/NjSQllWSIYjAQMukzgjctRC1YEABjqVIEb1hMyJiPQNcx7dyN4eEKAAQ88gjajt0Z79gx4GCxkDBvgcfakqmlkXTdO0MsGeHhzmSJX6IoBFSqREClSvf+ixXF2oEE1mtRsxnFYABA6Doi\/lbG+9V1RFISStlSXH+sAZw4g37xEvmHD\/WILWEPC96YrfDGI7DMDDEzFEqXh+ZtvXfHS2rISipxjvRG+xWFPA3ro1+9BkKgX7+OoWnDDPd3d+PP3HiyKfo3MXDiDKBgWbraXe\/gARQF2nUT5C8PLQIUJr8Kk57x2OGdRlZSSfZJXgJR27GbhKA8WHb9Tt43B2T4MuMjFeDUNYctAvYcwXLuHMayZd1eTTUNxg9VOH8GbP3Rl4FtmxQaP+U71VRWUolrMBjI\/9VE1DJlCBn5LgGPPZa+ZIpCwCOPkP90LJA\/xUN35y9y77kmo2mw\/n+QdN\/2L1p55PBOIyWVuAw1f36C27TGWLq001XQGBZG4PwxDluEx5q8gYEw9yQEpji6tZqej\/OdXl8pqcS1ZDaFriiEdO9KngVTbDuwN3k9MrF2BcGc+0QFmDrS7Yd2GimpxCfIG9UZ5dlmyT8J7ngw5HC\/qAKIne071VRKKvENVJWCPyyBalUAgfbV9x49fGoV1VeqqZRU4jsoCvlXzgVCQYsncesvHs31OooqgF9ne+zQ6SIllfgUxvLlyX9qEyAwLVvl8eM7ipoETPzQ+01eRQjXjwa5YZfouk5MTAwGg4GoqCh0T8+rKPEcQnAnZglJvd6nkDhpHSvxMGdPq7xYSUEFNosHx0wVD5rrV2EGXdfZvduaCXXHB4HER9A0hK6T2O5JDGPHElihgkdDtbYO6rajjCwd1YiVC0oS2cN74Qa\/klRVVRo3bkznzp29fSoSd6DrCJOJW5+MRVu6DnH2BhteeoGuHTu6\/dBCWAP2mga\/\/AQHd8KOT6AgoOVZAPTAeqXqefxKUsDezJWV1I3YSonqgS4LXUeYzSRuisW0bCX6zGXW7QWLke\/UVsTmzcmn5Nq\/t01KIcBsUlg2G9aOhPNXrRFBBajeHEbO19nyi3e7bvxOUokbEQJhMpEYuwXMZgLDG2AoXNj1PaxCIDQNLBbuzF+IacxXcOpM8oMKFC5G6NEtKEWKuKWZm5QEcScUln8LBxfC6cspH1eBFz+HV4YKNM37GV4pqcSKECT+vJm7rV8GbgOQSBB5dywlT4P6LpNFmM2Yj5\/g7heT0Geuwbo0ko17ghqKFUN3Q4eRyQStghVS27MC5AUWXYaixb0vpw05BCMBQJhM3G3\/KkqXRhRMukAhcQWlQWXuDBrhumNYLMQ\/05GEqk2Tm7WOgqqoXZ8h9M9YDMWKua2jyGCAyGEPbleBmq1goxA+JSjISioBEALzn0fgzjVCZ3yFEhgIQpD\/h0WowcEuE0YxGgmZNpHblRrc94iK2u0ZCiycbT8fd5Dcwk6xewUIBoYug7YdfUtOG1JSiVXSAwcBFTU01P5fbCha1HXCCIEwm7EcO451xc9bWHtLHQR1o5xmM0wepXByF7w4CvIXhDnvQtkQmHwSij3km4KClFQCoCgYSpcGBPrt26j58lmFsVgwHf6TwGpPWnthdd06iJ88TYrTaBqmY39x5413ELcSyPvbEu7832DY9xdqt7ZuE9RRziMbYNB0qP6Z9TilyymUfhie72r92VcFBXlNKgHr9CfNmgBG7i5ZZg0TmEzcXbuehBotMZ88yd0Nm7jZ5xVuz5jpfG+vEIikJBJmzSGhajuMXdpTaHcseerUJv\/3C8izbJpbBNU0SEyE6PcUXm+k8HQX+G6voHodYR9dCqsgeL7rvZ99GVlJJUDyJNhfDMf0n7cwz14Emo7Y9ieGEa9hKFKEO5O+osD8mdxZsYo7y1eSt2Nkuv\/dwmLBfOwvErr8B6VAPkIv78RQvLj9NcayZV0+RUpqlXPoZ6lXSl8X0xFZSSVWDAbyDRlE3l3rUKs\/gfJoBYJWfkXop\/\/FdOgwxrq1AMgb0Q7zps1p70cIRGIitz76mIQnIwj67AMK7tyUQlDb81xlijOV05+RlVRyDyHIU68ueerVvbdN09DOnkPJk8f6FE1DnDmX+svNZhJ\/2kjisNEoVSoQennHg3K6kMxUzhTn6cFAlSuQkkpS8uDtHhgrlMdy7C\/742qlhx94jbh7l5uD3kaftZGQPcsIrF4t9f25gKzKCdYww9GDCn\/uhaZtoURp4fOy+vjpSbyOohBQpTLaHwesMb7FSwlonTwpdnKM8O7a9dzI9wRK4cIUshy3CuqGdmZ2m7X\/XFLoEaTQvy582Q+6lIMvR3n\/ftGM8IlKKoRA13WEEAghUFUVVVU9es+eJG3UggUJjHye+Bf\/D2PLpgQ\/94x1eMZhWCVk3\/f35HQxum7N22alctrQNJg4FG4CS+OgdJhg6qcKc9+Drv0USpaR46RpIoTg3LlzLF26lH\/++Ye\/\/vqL8PBwWrVqRY0aNbx9ehKwLinRsjlBLZsDIBITuTNvAab\/+5iAqSPI1\/\/\/rM9zQ+U0mSD6PTj8o5IlOW3oOvwxH7pPsAoqBLz6ruCZKN8WFHxAUk3TGD16NOPGjaNQoUIAXL9+neHDh\/Pee+8RFhYmb0vzBYTIcFjFVdiuOb8caeDHH4xEz4O3xmQvdKDrEA8UK3VvmxBQ7hHfFhR85Jo0ISGBQoUKoWkamqYREhJC\/fr1OXbsmLdPTQLOD6tkk\/uvOVt3Frw62kK12tm\/xFUU67xFCQ7rSAkBJ48p9hUXk0NWPofXJVUUhRo1ajB27FgWL15MTEwMM2bMYMeOHYSHh8sq6mWE2WztGKrTEv3IcUIv7yA4op2Hxjl1l0mjqlClMXw\/0lpVzWa4dEGh72Mw9RNr59GJIwrvdPG9jiSvN3cNBgPDhg3j4sWL7Nmzh1u3bvHss8\/y6quvSkG9iQeGVTIaSnHln99ggDe\/gv+rBm0NCg9VgvPHIR\/w8lDBn\/sVZnwEN8+77piuwuuVFKxTohw+fJgZM2bwww8\/8Oabb9KxY0f27t0re3g9jQeGVbyREFIUqPKkYMVleO5DCC0HL0TD0ruCoCAoUw7GLxVoJtcfO7t4vZKCtcnbqlUrWrW6t5zVtGnTCAsL8+JZ5ULuu1vF1cMq2QkhuAIhrDMuDPoo5TaA0IICkw8KCj5SScHay2symTCbzSQmJpKQkMD+\/fu9fVq5gzTuVnGVoL6UrbUd7\/7j+vKVlU9UUl3XiY2N5X\/\/+x958+bFZDLRunVrWrduLa9L3Yw7h1W8XTmzguH+5dV8AI9LKoTAYrEQEBAAWAU9dOgQLVq0SNHctT1X4iaSq+etT8aifTKPoFWTrL22yY9lB3+UE6ydS33He\/ssHsSjzV1bxaxduzYJCQkAHD58mBo1atCzZ08AezRQCuo+3DWs4kvN2qygqtCwue+FGzwq6ZUrV3juueeoV68eiYmJKIrCk08+yY4dO1i3bh1z5syRvbnuRAjEnTvcfG0QiZGDCFkwjYLLFmS7eevvcjrii+fqMUl1XWfLli2YzWa+\/fZbihYtaq+WderUoWnTpmzdutVTp5O7SJ4E7O6adS4dVslJcvoyHrsmVRSFhx+23od45swZypYta38sKSmJv\/\/+m0aNGnnqdHIPycMqdydORp+5gZD9P1gnFstm5fTHa05\/xaOS1qhRg3r16tG2bVveeOMN8uXLx507d1i5ciUXLlzgpZde8tTp5HySQwn2u1UmDKaA5Sv7Y1lByukdPNq7azQaWb9+PaNGjWL69OkcPHiQUqVK0bhxY7Zu3cpDDz0kO4xcgLBYMP913BpKuH0n28MqUk7v4vEhmPz58xMdHZ3qY1LQbJJiWGVutu\/1lHL6Bh6VVNd1Nm3aREhICOHh4WzYsIGQkBAaNWqUaUFtwzS6rqPrOkajEdXXJ6txI\/ZQQtTLKI89nK3qKeX0LTwqqaZpREdHExwcTHh4uP17ZzuMbFImJSURGxvLxYsXWbhwIXv37mXq1Kl06dIl91Vjx7tVvttA0Ipogts\/b38sM0g5fROPSqooCgaDgZCQEIQQ9u+dQQjB6dOn2bVrF927d0\/xmMFg4MKFC3aJHY+XY8ddk2dKSPxxA4kRr2MY2pNC+gn7Y5lByunbeD2762zlUxSFRx55hMqVKzNq1CjmzZvHl19+CVgl7dq1K4sWLbJLqaoq9erVSzHUk2Oawy4aVpFy+gdelzQz2K5Da9euTe3atRkyZAgLFixg2rRplCxZMkWFFUKwefNmdu7ciaIolChRgiZNmiCE8N8K66JhFSmnf+FXkjoihKBs2bIMGzaMYcOGpVqRW7RoYf\/+9OnTxMTEYDAYqF+\/PmFhYWjJK0kbMrtKmBdwxbCKlNM\/8bikBoPB3uw0GAzZEiSjprLj4xUqVKBChQoAnDp1imPHjvHDDz+QJ08eXnjhBQoUKJDl83ArLhhW0XXr1JhSTv\/EoxdpBoOB999\/n1deeQVFUezfewJbU1nTNHbs2EG1atUICAigW7duzJo1i\/j4eI+cR2YQFgumP49wo3aL5LtVdloFdTIYa5Nz8zqF1xrKbK2\/4vHe3bp1rYsBCSFSfO8pzp49yyuvvMKECRMYMGAAQgi6devG8uXLad++PYqi2Of\/9RrZHFbRdevUlNs2KMSMgerPwMx9snL6Kx7v7nS8V9T2vdlsTvFlsVgwm80ul1fTNGJiYqhYsaJdULDGFePi4mjRokWKHmKPk9rdKvoJq6BOlD7HyjmwpcLRfTB9u+D192Xl9Ge83nFkNptp0aIF8fHxVKpUCYA8efJgNpsZMWIEderUcamsd+7cYdCgQfafNU1jy5YtTJo0idGjR\/Paa695JxCRjWGV1Crn9O2ycuYUvC5pQEAA27Zto3fv3sybN++Bx10pjKIo1K5dm8uXLyOEwGQysXr1al599VUmT55Mr169PC9oNoZVpJy5A69LClYRR44cyfXr1wkNDbVvd\/V4pqqqREREMHv2bKZOnUpsbCx79uzh9ddfT1dQXdfdEoTI6rCKlDN34ROSgrXnd+3atSmkbNy4sVsWbOrTpw83b96kS5cu3Lhxg99\/\/z1dQbdu3Urz5s1ddwJZHFaRcuZOfCYnpygKRqMRo9GIyWRi48aNbuvAEUKQP39+ihYtiqIoTJ8+3f4B8ffff6cQVlEUKlSowJYtW1zyYZGVYRXZIZS78YlKqigK5cqVo2zZsiiKgqZp6LrO0aNHU2Rv3UHFihWJjY0FrJ1Y3333HQ0aNLDP+Ws7NyEES5YsISoqKmsHysKwiqycEvARSYUQ\/Pzzz\/bJsRMTE3nooYfo2rWr2ztyHPf\/999\/c+PGjVQn5a5QoQLly5cnJiaGrl27ZuYAmb5bRcopccQrkmqaZo8D2ibLfuqpp7w6ObbZbGbKlCm8\/\/77qR7Xts12t023bt0y3mkmh1WknJLU8Pg16eXLlxkzZoz9evP8+fPUrFmTRYsWAd6ZHFvXdTZv3kz16tUzTBsJIWjYsCGbN29O+5pZpFxbxfB4FesUmmkIKq85Jenh0UqalJRE69atuXnzJi+\/\/DIlS5bEYDDQqlUrevToQcWKFalbt67HxyqvX7\/O+vXrmTBhQobHVhSFsLAw4uLiOH36NBUqVEjxmswMq8jKKXEGj1VSIQQ7d+7k0KFD7Nmzh1KlSgFQunRpoqOjadKkCQsXLvTU6aSgSJEiTJgwgRs3bjj1fEVRaNKkCbt377Y31y1m870l620rk+36OVVBZeWUZAaPVVIhBDdv3kRV1RSz19uSPwEBAfb7O72BECJTt6spikLHjh2ZOXMmu3ft4tzu3czTQ6BiWJrVU1ZOSVbwmKSqqhIeHk6BAgXo168fH374IUWLFuXff\/9lzZo17Nq1izFjxnjqdLKNRdMY+PrrTPvmGwACDAbyLFuR6rCKlFOSHTx6TVq4cGHWrl1L165dmT59un17aGgoEydOpF69en4z259isVBPMTBNSLFpJQAACsJJREFUUaymqSp7ixWhMfd6gqWcElfg8ftJGzRoQFxcHCdOnODAgQOUKlWK6tWrExwc7B+C6joiMZHbg94mcs5GAseN44V33kEIwcULF2xPkXJKXIbX7ietWLEiHTt2pEGDBgQFBfm+oLZhlZmzuZGvqvVeT9Nxer31FqdOnqRYsWIsWhSDpskOIYlr8VriyOeldODBYZVd9o4hAYSFlWPr1p280GkK\/1cXwnvKyilxHT4TsPdJhEh3WMU2lBK7VmFcnzBe6PYZ3+0V9H1LVk6J6\/CJ7K4vkt7aKqldc07bJiunxD1ISe\/HVj3HfI728VyCVk0iOKIdALomZIeQxOPI5q4D9knAQh6HRBOhl34lOKIduiYwJQnZISTxCrKSgn1Y5eagt9HnbLTfraLrYEoSsnJKvErurqT3D6sUtQ6rGJ980lo51yIrp8Tr5NpKmtqwilK8uEPlVGTllPgEua+SpjKsUmDXz2gFi7N5taycEt8jV1XSFMMqjz9Mvos7oahVTnnNKfFVcoek9w2rBK6YRGD7dvyyFmI+lXJKfJsc39x1HFbR75oIitvBrjztGNAYjv4hm7US3yfnVlKHYRXLdxvJ89tqdl+tSkwPqN5WVk6J\/5DzKqnDsMq\/+apizleYAxuP89bgqhz9HaZvk5VT4l\/kqEpqG1a5PfAdLNfvsH\/+7yyYUITGZa1yghRT4n\/kDEmTq2f8x5+R9Okcdj77FuuMr1PtJMz6Xcop8W\/8XlJhsWA6epz4Dv9h28mHWVF8Dy1aF2LaYCmnJGfgv5IKHS3RxI3RX7B57AYWM5U2k2oy7w0AIeWU5Bj8UlJh0bi57mc2RkxjEcNp++X7LB4AUk5JTsTvJLUkWljzynJmzwyj7aSlLJGVU5LD8StJha7w5Yt76fHGUJaI4kg5JbkBv5FUVVV69OxGYJBKl87F\/WoiM4kkO\/hVmEHXdTSLlFOSu\/ArSSWS3IiUVCLxcaSkEomPIyWVSHwcKalE4uNISSUSH0dKKpH4OFJSicTHkZJKJD6OlFQi8XGkpBKJjyMllUh8HCmpROLjSEklEh9HSiqR+DhSUonEx5GSSiQ+jpRUIvFxpKQSiY8jJZVIfBwpqUTi4\/i9pEIINE3z+yk+be\/DYrGgaZq3T8fjWCwWdF339mn4JH4nqRACIQQWi4XExER+\/PFHPv30U3777TcURfH26WUJXdc5duwYo0ePpkOHDvzvf\/\/LVf+wFouFgQMHsmjRIiwWC2azGU3TctXvID0U4YYS5K6qpmkaY8eOpWzZssyfP58NGzYAoCgKixcvplOnTn75h921axdPPfUUFStWpHLlymzatIkqVaqwY8eOTP0ubR9g\/kZSUhIhISH2n+vUqUOHDh1o1qwZFy5cICoqymvvS9d1lixZQrdu3VKcgycLgt\/MYA\/Wf8KdO3eyZs0afvvtNwwGA7quo6oqO3fu9Ltmr6qq1KlTh88\/\/5z27duzaNEiAPbv38\/AgQO5cOECpUuXduo9CSE4c+YMu3bt8rsWhcVisX9vMBjYt28fly9f5vr169SrV8+LZ+YjCDeg67pbviwWi4iJiRFCCHH27Fnx2WefifDwcBEUFCRWrlzpjrfidpKSkkSRIkXEwoULhRDW350jmfn9+Csmk0kAonz58mLEiBFi165d9sccfy\/e+LJYLKmegyfxq0oK2JuzZcuW5Z133uGdd97hwoUL9u3CjyopWN\/PtWvXCAwMtG8TQqDrOoqiZKoq+tt7t6GqKtu3byc8PNy+zfY7kPhhx5ENkXz9JYSgdOnSlC1b1i\/\/SVVVpXr16pw\/f96+zWKxMGPGDHbv3p2upLquY7FY\/L5nVFVVwsPDU\/xNJffwW0kd8ec\/rKqqtGnThujoaP744w+SkpJYv349gwYN4uLFi0DKqmJ7r7qus3r1al5++WX69evHxo0b\/e5a1BF\/\/ft5Ar9r7uY0DAYDw4cP59ixY9SqVQsAo9HIsGHD6NChAxs2bODxxx9n\/\/79tG7dml27dhEcHEz16tXZvn07c+bMQQjBsGHDaNOmjZffjcQdSEl9gIIFC7Jy5UpOnDjBgQMHCA8Pp0SJEphMJiZOnEibNm3QdZ3o6Gh69+7NunXr+OCDD\/jnn38Aa\/P48uXLXn4X7sGfWweuQkrqIwghqFixIhUrVrT\/DBAQEMAbb7yBpmls2bKFF154gcDAQPbu3cutW7fsr79586ZXztvdlCxZ0tun4HWkpD5EetdljmPAuq5jMBioUaOG\/fr0scce89RpegxVVWnatGmuv16Vkvo4BoPhge8VRUFVVYKCgvj6669JTEykTJky3jpFt5LbBQUpqU9jNBoZMWIEYBX0zTffBCA8PBxVVenatSu7du3CYDBQp04d+Q+dQ5GS+jCKotjlU1WVxo0bI4SgXLlygLXK1K9f3\/69JGciJfVxHOWzfZ\/aNknOJUeEGSSSnIyUVCLxcaSkEomPIyWVSHwcKalE4uNISSUSH0dKKpH4OFJSicTHkZJKJD6OlFQi8XGkpBKJjyMllUh8HCmpROLj+PVdMP\/f3hmztLKEYfiZMduImEIIhoCgpZDCylgEC3sNKhER\/4CVpNAyIAELQSy0EBEsxBAQRRBbwUawERREu4CgCLEQBcmymzmF7N7cq4drDtdk9u483c7Csjv7fTvfzCTv66kSeEoFUob7m1Mv7SmlJBIJ9OttOrZt+3Gkk7ZS4KLaS0zbtrm7u2NpaYmhoSEODg606thm8\/T0xNzcHIlEglgsxuzsLC8vL62+rcBg2zaxWIxcLsfp6anvbqeDnnHgDJuWl5dRSrG\/v8\/19TXwoVpQKpUYHx\/XolObjeu6TExMcHt7S6FQoFqtsri4yMjICLu7uw29jzD2H3w2jerq6mJmZoaxsTEqlcon0yhj2PQblFJcXFzQ0dHBzc0NlmXhui5CCM7Pz3EcJ3R\/gpZSMjg4yPHxMVdXVySTSQB6e3u5v79v6Fq1Wo1SqRTKaYNnGiWlRErJ29sbl5eXWJblq1+0jJ8wmGmGYZNSSp2dnalcLqeGh4fV4eHhTzyK9tRqNVUsFpWU0j+uNxRqtI\/Dim3bKh6Pq+npaXV0dPS3c8awqUHq7RbS6TTpdNo\/p0I2isJf8p5ftTuOQyQS+VZpppRCCBHKPoQP0beHhwf\/WNXJp7aaQNc1qs7gJ6zBJaUklUr53q1KKVzXpVwuMzAwwOPj478maaVSoVwuh3rhDdA2lgI3kho+E4\/HyWazTE1NsbCwgJSSra0totEoiUTCn6t7er2u6\/pzr2q1yvz8PJlMhr6+vlY\/iuELTJL+D2hra2Nzc5N8Ps\/KygrPz89ks1lWV1dxHIdCocD7+ztCCCYnJ1lfXyeTyTA6OsrGxoYvEWrQk8CVu2FcefwOnZ2drK2tUS6XeX19ZXt7m2g0iuu6FItF8vk8sViMk5MTdnZ22NvbQ0pJLpcjmUxqV+LpRKtjLlAjqRCCVCrV6tvQlq8STQhBf38\/7e3tdHd3Y1kWjuNg2zbwsTBiEvT36BBzgRqWhBD09PSYoGoQZcS0\/xgdYi5QSQomyBpFCIFlWcBH2eZt13htXnurSzqdaXXMBepngYY\/w9v\/9LZY\/rknWt9u+B7N3K76kSQ1GAz\/HabGMRg0xySpwaA5JkkNBs0xSWowaI5JUoNBc0ySGgya8wvwNNctS+31ZwAAAABJRU5ErkJggg==","width":273}
%---
%[text:image:9617]
%   data: {"align":"baseline","height":461,"src":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAAOsAAAJCCAYAAAAhhjDaAAAA4WlDQ1BzUkdCAAAYlWNgYDzNAARMDgwMuXklRUHuTgoRkVEKDEggMbm4gAE3YGRg+HYNRDIwXNYNLGHlx6MWG+AsAloIpD8AsUg6mM3IAmInQdgSIHZ5SUEJkK0DYicXFIHYQBcz8BSFBDkD2T5AtkI6EjsJiZ2SWpwMZOcA2fEIv+XPZ2Cw+MLAwDwRIZY0jYFhezsDg8QdhJjKQgYG\/lYGhm2XEWKf\/cH+ZRQ7VJJaUQIS8dN3ZChILEoESzODAjQtjYHh03IGBt5IBgbhCwwMXNEQd4ABazEwoEkMJ0IAAHLYNoSjH0ezAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAgAElEQVR4nO3df5xbdZ0v\/tdAgRSFxH24O0FXJsV1J95db2dctRkUJ+CPBlGbQeykXqTp+qPT9UpTUTqjaFMEJtMLNi13bQZlO+VXk1LaDBabUYGEHzaj3iXjrkvG69IEv0jG9WsnIjRF8Nw\/wjlNZpLMOflxck7yej4efTCTySSfoX3N53M+n\/f5fDoEQRBARJp3RrMbQETyMKxEOsGwEukEw0qkEwwrkU4wrEQ6wbAS6QTDSqQTDCuRTjCsRDrBsBLpBMNKpBMMK5FOqBbWr7mBZ4+r9W5ErUe1sOb23YD\/cRHwg6M\/V+stiVqKKmFNp9N4xvkLXLTmCL7xkbfha1u\/g+npaTXemqhlLFPjTeLxOOLxOIaGegAAD++4GidztyORSMDhcKCrq0uNZhDpmmphzWQyMJvNeNflz+Gu3EP46e7rgWt3IJOZgNlshsvlgtFoVKM5RLqkyjA4lUoBACKRCK7YuBF3\/OVR9L7jVvx49xeR\/f1yZDIZ+P1+TE1NIZvNqtEkIt3pUGMPpo6ODgCA0+nE4cOHAQDzH70Khx4C7sDduPja22H8i5PS8+12O\/r7+xvdLCJdaXhY0+k0LBaL9Hnh253ovQTf+0sPvvPDT+Dd1+4oCqzBYIDdbseqVasa2Twi3Wj4MDgej5f92nnhe\/CxH16Pz33oAfzr7uvx9r+9VPpaLpdDJBLB+Pg40ul0o5tJpHmqhzUUCkkfL+vqwnmpR\/CxH16Pf\/zQA\/j2p96PKz+2DTabTXpOJpPBxMQExsfHeT1Lba3hYRUnl8oRA9vzw8+g98MH8cV\/AN7+t6vh8XhgNpul53ESitpdxWvWUCgEm80mrYOm02nE43EMDg7Kf4PXJpdEhZNMhV4KHsCv1n0eez\/8XTz1g6tw1zPAhSvy7xmJRJDJZIqez0koajcVe1aXy1U0jI3H43C5XLJfXMm15rmutfib\/Xdgww8+i94PH8Q1F+Vribu6urBx40bY7XaYTCbp+dFoFGNjY5iZmZH9HkR61tBhcFdXFwRBgCAIcDqdEAShZK8qOte1Fitu+So2\/M6P92x6QgosAPT392Pz5s2w2+3S83O5HMLhMCehqC1o7ha580aux4UXmHH19PCiwAL50Ho8npKTUKFQiNez1LI0F1YAMB05WDGwRqMRq1evhtvtLpqESiaTnISilrVkWHO5XMmPgfw16eTkZEOCYTpyEG\/5cwc2XPjjkoEFTl\/Put1uGAwG6fF4PI5AIKDanT3bt2\/nMJwarmJYrVYrotEogHwwJyYmpK9NTk4iEAggl8vB7XY3JLDnhe+BeWQcGy78MTpXH8SGEoEF8qHdunVr0SSUWFTR6EmoUCgEr9cLq9WKLVu2YG5urmHvRe2tYlg9Hg8mJibQ0dGBnp6eoskds9mM0dFRDA4Owul0VqxUqpa4Bmse3Yu97j\/jjasPluxhReIkVOH1bKMnobxeLzweD6LRKJLJJKxWK\/bt21f39yFasjY4nU4jkUjAbrdjfn6+5Drr9u3b4fF4Kt7iNjAwUHEmuJJX0mm8YLkM56Uewf\/Y+FPMTZ1ehy0nm81K99EWslqtcDgcdbkdb3x8HMPDw0gmk+js7ASQ72ndbjeCwSDWrFlT83sQiWou5B8fH4fNZsPKlSsrPq+WsAL5oolT60akwP5u6irsXSKwQPmiCpvNBpvNVnVos9ksrFYr3G43RkdHi762ZcsWJJNJHD16tKrXJiqlptngXbt2yQpqPZzrWotz9o\/iBctluHf83UsOiUWNmoTy+\/2Yn5+H3+9fdK2aTCaLZqnHx8cxMDBQ1fsQiaruWcfGxhCJRKQJneHh4Yq3s9Xas4peGN2BV\/\/15zDdfw8GHQdlDYkLxWIxJBIJzM\/PS48ZDAY4HA7Zv3Tm5uZgtVrh9\/vR09OD4eFhxONxOBwO5HI5xONxRKNRdHd3I5vNwmKxIBAIKCrTJFpIlZvPgfqFFcjfuA7kl3cGHQdlD4kLTU1NLbqeNZvNsvaE2rJlCyKRCJ5++mnpscnJSbjdbgwPD2Pr1q3S4yMjI4hGozh27Jj8xhGVoMuwAq8Fdrmh6h4WKD8JVel6dnZ2Fj09PSUnkMbGxhCNRqVr1bm5OVgsFkQiEd50QDXTZAWTHKYjByH8Ko2XggcQilyFTpnXsIXKVULF43GpEmohMdjBYLDkUlDhRJbX64XD4ZCCGgqFsGvXLsRiMfmNJHqNbsMK5IsmTq0bKQpsucKJSsRJKKfTuWgSamxsrGgSav369UgkEgAgFULMzs5iamoKPp8PDocDADAzM4NAIACv1wsgH9Th4WHMz89jeHgYfX19mJ2dre1\/ALUV3Q6DReIa7Dn7R3Gua23VQ+JC5SahXC5X0fXs9PQ0fD4fwuEwAMDtdmPv3r0A8j+v2WzGnj17pOdns1lpaL19+3ZMTEzg+HGeKULy6D6sQHHRxLKurroEttz1bKlJKLHUUgxiLBaDw+FAKpVCZ2cnxsfHEY1GYbfbpf2RZ2Zm0NPTg\/n5+YprvVNTU1i9enV1PwS1lJYIK1BcNCEG9ndTV+EL+4Arr6n+dbPZLCKRCJLJZNHjlSah+vr6YLfbMTo6iu3bt8Pv98Pr9SKRSCAcDsNut0s3RYiTUWJvbrVapXCOj4\/D5\/Ox96U8QSVOp7Ph7\/Hi\/pDwe1wk\/CmVEgRBEMZuOSD0QxAe2Ff7a6dSKSEQCAher7foTyQSWfTcQCAgzM\/PC4IgCHa7XfD5fIu+DkBIJBKCIAjC0NCQYDKZBKfTKdhsNsHtdgvz8\/OCyWQSgsFg7Y2nltAyPauosGgCAHaM3o\/vf\/WTuLbGHlY0MzODSCRSdLtgpT2Ot2\/fjkgkgkgkAqPRiGw2C6fTCbPZjP3792PXrl1SrysOrS+\/\/HKYTCakUimuz5Kk5cIKFBdNAPnABr\/6Xtyw7011CSwgfxIKyK+\/Tkzkz\/RJpVLIZDJIJpMwmUwlq5t27dol3cnD9VkStWRYgeKiCQA4sP8x+D71N3UNbKVJqFIHbWWzWfj9fiSTSezfvx9TU1Nwu914\/vnni563adMmpFIpHD16FNlsFoFAANFoFFarFUNDQ+ju7q7PD0C6osopcs1gOnIQJ3ovwUvBAzjXtRZr170fwGO46VMAUJ\/AikUVNputaBJK3ON44SSU0WiEx+OR9lLOZDJFR4sA+aqnYDCIaDSKbDYrrdu63W7Mz8\/D4XAgGAzyWJE21LI9K7B4DRZoTA8rUrrHcTabhdlsRjwex8qVK5HNZuFyuWCxWLBnzx5s2rQJExMT0hIQkC+u8Pv9vJZtQy0dVkD9wALlr2dLTUJNTk7C4\/HAarUilUohlUpJ17NmsxlutxvhcBhDQ0PweDzI5XIwm81Q6a+NNKTlwwosLpoAGh9YIB9acQ8rUbmiikwmA5\/PJ22XMzk5iaGhITz\/\/POYm5uD1+tFJBKBzWZDMpnEU0891ZhGk2a17DVroWVdXdKN62JgG3ENu1B\/fz96enqKJqHEPY4LJ6HEP36\/X\/rewtMHOjs7sWfPHszMzMDr9cLpdNa\/saR5bdGzihZWOQHq9LBAvvcMBoOKtpfp7e2F0+nEtm3bAOSvV3kDe\/tqq7ACi4smAPUCCyibhJqbm8PQ0BDi8ThyuRxMJhPC4bAq2+iQ9rRdWIHFRROAuoEFlE1Czc3NYX5+nuurba4twwosLpoA1A8sIH8SiqhtwwoAJ3ovwTlbvygt6QDNCazSSihqT20d1lJrsEBzAgtUNwlF7aMtlm7KEY\/neMFyGQBIgVVjWacUo9GIjRs3LpqEisfj0qkILDNsX23ds4pKFU0AzethRfXY45hah643TKuXwqKJVwp2LFy77v0Yvu9XuGn9b3DoLvXb1YyDtki72LMWKFU0AeR3S7zmItTtBvZqqHHQFmkbw7pAqaIJQBuBBRp30BZpH8NaQqmiCUA7gQXyoQ0Gg7K3lyH9Y1jLKFU0AWgrsAAnodoJJ5jKKDyeo9CFK4C7ngF2r0dTJp0W4iRU+2DPWkG5oglAez0swEmoVtfWRRFLKVc0AZzuYa+5KP+5FgIr7glltVqLJqGSySSSySQnoXSOw+AliIE9tW6kaA0WAIQz0njntTuatg5bTqNOe6fm4jBYpsI12CdTKYTDYWlnh9gjz+Ibl71FU0PiQkr2OCbt4jBYJnEIvNqyAo\/g9O83n8+H91\/6FmlI\/H8eAW6eaE4by+nv70d\/f3\/Rae+5XE7aXoa34+kDe1aFnvbtwH8b2QogX4hQuCVoOp2G0\/IcelZejL2JZrWwsmoO2iJt4DWrQr\/tW4Ub1+Q3LAsGg0Vf6+rqQjj1ZiRmfoyN729G65ZmNBoxODgIt9stbTYOVD7tnbSBYVUgFArBYrHg6+HD+PnHroTxC9cteo4Y2J88\/mNs6GlCI2VIp9NwuVxwOByyTnsnbeAwWIZ0Oo14PL5oZ8FSO00Ufo\/T8hzec8nFGH9MrZYuLZ1Ow2azIZPJIJVKSdeqnITSPoZ1CbFYDAaDoWS9baWiCUB717ChUAgejweZTGbR9Tag7LR3Uh+HwRWIw95yhfGFa7ALyxKB00Pis89H04fE4tBXLJQoLE8UiUUVC4fG4sbkU1NTyGazqrWZirFnLaHcsLeccjtNFBLD2swetnAIHAwGl\/z5Su28COSDvnr16ga1ksphWBcIhUIwm82KDzEud+N6oQ09wNnno2nXsLFYDBaLBcFgEFu3bpX9fVNTU0gkErwdr8kY1tfEYjFkMpmajqeQG1hA\/R42nU4jk8nUFK5Sk1C8nlVP24dVHPLabLa6\/IMrt9NEoWb0sPU6J4d7HDdPzWGdnZ3F8PCw9Bt2zZo1ABaHU4thrXbIu5RyO00UUrOHFYe\/9ez9uMex+mqeDQ4EApiYmMCePXtgsViwb9++erSroUKhkNTT1DuowOmQzn\/y6rLPEUPa6EqndDoNg8FQ92GquMex2+2G2WyWHhcroWKxWF3fj+pcyL9y5UoYDAZMTk4WTf03UigUQiKRgMlkwtDQUNnf6OJwF4AqxyaajhzEid5L8FLwQMk1WCAf2A09+T+N6mGVzGpXQ7wdb+H1bDQaRTwe5yRUHdXcsw4NDcHj8Uifd3d3w2KxqBLWDRs2wOFwYHR0FKlUCkNDQ2Wfm0qlMDg4qOr5pueF7ym7BitqZA+r5nmu4vYydrtdeiyXyyESiXB7mTrR7QTT1NQUAoGA9JrpdBoWiwUq\/TiyLVXlJKr3NWwjrlPl4iRUY9StgmlgYAADAwNYt24dent7MTY2Vq+XLslkMhXd5mUymeBwOBr6ntWotNNEoXr2sI26TpVLrITyeDxF17OZTEa6s4eVUMo1pGfNZrPw+XwYHR2VHmvEbPAFF1yAcDgsDbfm5+dhMpmK3lcr5KzBArX3sOl0GqlUqiETZ9VScto7lVe3sIZCIenjTCaDXC5XVCVTr7AWFi9s2bIFBoOhKJyXXnopDAYDjh49WvN71ZuSwFa7DqvmdapSSk57p8UaEtZSa5eFYRV3kw+Hw\/B4PGX\/cYnBLFRYvDA9PQ2Xy4Xjx49LXxevXZPJJLq7uzE+Po5kMolcLgefz9f06yU5RRNAdT2sloNaiKe9V0dRWCcnJ6WiB6UGBgbgcrmkkIo8Hk\/JO0AAyKoqWrFiBSYmJop+OfT29sLr9cJut8Pr9WLnzp2IxWJIJpPYuHFjVe2vJzlFE4CyHraZE0pKpdNpuN1uDA8Pc49jBRSFdfny5QAAh8Mh\/ZH7j6Ovrw9msxmJRKJoOxGn01nT8HhkZASZTAZ79+6VHrv00ksRDodhNBoxMzODlStXIhQKwWQyaeZukXLHcywkp4fVU1BjsRhcLhcsFguOHTvGSigFFM0Gnzx5EuFwGFarFYFAABaLBb29vdi+fTtmZmYqfq\/ZbMbhw4dx\/PhxpFIp+Hy+RfdNVsPtdiMcDiMUCmF2dha7du3C8PCw9JcsnvcSiUQ0E1Sg\/PEcCy01S9zsmV8lQqEQ7HY7MpkMnM78PlaFlVDc47iymq5ZY7EYvF4votHokj1kI2uD+\/r6MDQ0BJvNhu7u7kVfD4VCMBgMWLNmDWZnZ0s+pxnkrsECpXtYLc78ljMwMFB0+VO4pUyhWiehCudO1KLWPIGisO7btw+JRAKJRALxeBwmkwk9PT2w2+2w2WwV\/9E0MqxjY2NIJBLYv39\/2fe2WCzI5XJFNxtogdLAitewegoqcHr4W25LmYUK9zgGgEQiofjSq1pbtmyB0+nU3P9bRWHt6OgAkB96ejweRUcKNjKss7OzsNvteP7550t+fXJyEjabDZ2dnQ15\/1rJ2WlCJPawQ+PTulvuCIVCiMfjMJvNsm5+L6yESiQS6OnJ\/\/CNnoS64IILMDw8jM2bNzfk9aulKKxi0bz4P9BsNkv\/42w2W8V\/PI2+Ra6vrw+RSES3ExJy12DT6TT+yXIW\/mrlmzSxCZtctYwE0uk0vF4vLBZL0eONmISKxWKw2+01T3w2gqIJpsHBQYyOjuLRRx\/FyZMnMTExAYPBAI\/HA5\/P16g2ynLs2DHdBhXIH89xzv5RvGC5rGxZovgP\/iHhTQCavwmbEvF4vOphZVdXFxwOhyqTUOJ1deH1tVYorg2emprCyMgIent7YbfbkUqlMDw8DK\/X24DmtZdzXWux7JaN+OOXv7boawt7JrXuh62HWCxWdi1dia6uLmzduhV2ux0mkwnA6Tt7xsbGllyRkKPwlIVmTFZVoiisy5cvh9PpRCKRwNDQEFKpFJ566imMjo4qun6l8s4buR44mZMKJ4DyQ8i9CeCNFwH2jvzhzlrUiKWlRp32vrBibmHBRrOpWsGktWsALROLJrK33rzktd6hu4Dd6\/OHO1+4QsVGylCvEshyr9OI0961WrapqGc1mUzSdh2xWIwL1g1kOnIQT6aO4+mdu5a81rvyGuDaffkjJ7XUw6rxj168HW\/h9jLJZLLlDtpSFFa\/349AICB93OxJpVYWi8VgvfUWrNo1uWSVE5APbNeaI00J7OzsLC699FIMDAxIj6XT6aLwNFql095b5aCtmm4+V2ufpXYjHtvx1v7+isdzFBobG8OBqU9CWHmrqoEVz3v1er3SL3IgH55mFBUsNQml5+1lePK5hpQ6tkPcaeIFy2U4u29VyTXYsbExeL1eBINBrFmzBh+\/9Lu45qLPqnING4\/Hi4oHZmdnpcOarVZr0woL+vv70dPTU3Q9q\/fT3nkwlUaIM76lrvGWdXWVXYMdGxvD8PCwFFQAePDRz+J8+3dV62GnpqYwPj6ODRs2SCWFBoMBgUAAvb29TdvCpXB7GavVKj2u14O2GFYNEJcMKg0bSxVNiD2qyWRCIlFczqRWYFevXg2LxQKHw4G9e\/fC6\/VidHQUO3fuxNNPPw273d70uY3C095L7XGsl0koDoObLBQKyT6641zXWrx6PIU\/fvlrGH\/XO6Shr9VqldYct23bJj3\/wUc\/i2\/d+ByuuejNDR0Si3cxzc3NFd2rDAA7d+7Epk2bGvPGComTUDMzM4hEItJBW2Ltsda3l1EU1uHhYekHLPyYlFN6rKTovJHr4f3bv8P2g\/ciHA5LQ1\/xvB6gOLBf+sabkTv5n7jmorc2\/BpWHPo6nc6iXz6FQ1AtWLlyJVauXFl0O544CVXqiEutUDQMXrVqlTRUK\/x4enoas7OzmJ2dxYYNGzA+Pl7\/lraQUChU9vpUjum3Xoh7330x+u+5X3qsu7sb8Xgc0WgUc3Nzp587PY3\/FXgXutYcwYYGDYljsRjS6TSMRiOcTifsdjtCoRCy2Wx+CUpjYRX19\/fD7XYvqoTK5XKa3Ji85g3TJicnpeulTCaDPXv2IBaLIZVKYf369dLzWMFUfW9azoneS3DO1i+WvQ92ZmZG2odq8+bNDal0KnWU5NjYmFQIPzQ0VPTvoFqNLrAQl6AK96IGNLa9jFAjt9stfez3+0s+LgiC4HQ6a30rXQsGg0I0Gq3ra\/4plRJ+j4uEF\/eHFn0tHo8LJpNJ8Pl8RY8\/sE8Q+iEI6Wdqf\/9UKlX3n6mcYDCoyvukUikhEAgIXq+36I9aP2clNc8GO51ObN++HQCkNbWRkRG4XK5aX7olpNPphp1YV7jbf2HRxMzMDBwOB4aHhxfd5F3P0sRabnvTqq6uLphMJjidTqmoAoA2rmXrkfhUKlXxc0Foz561Eb1pKWIP+6dUSkgkEkU96vz8vDA8PCw4HA7B6\/UKmUxGEITae1i1erpmvF\/he0WjUdX+HpdSl6Wbrq4uqS7UYDAgl8vBZrPJ2rqjFRWeGqAGsWgi8veX4NPLXpB61NnZWTgcDlgsFjidTqRSKdjtdkQiEVx5TX629pqLlF\/D1uv+VD3Q0sihbuushZNHMzMzi9bb2oEY0qU2j2uEc11rcWdoP66dehzXuVzIZrOw2+1wu91Fx4uYTCZ4vV7s3bsXV16Tf2ypwBbuS6ynPYpbTUMqmEwmEyKRSCNeWpPE61KLxYLBwcGm\/UM+fPgwvvz16\/HHL38NgUAAVqt10SFdDoejqNpJzjXs8PAwbDYbdu3axaA2Ud161sJhsNlsxvDwcL1eWrPEpRiz2ayZm5XPG7ke8x+9Cj8YHoHTv3PR1yORiDRxMj09DavViiuvyS9LlOphC0+MF49wZFibRK2L41aaYEqlUpqZdCjnC6sdwhdWO4oei0ajgsFgkNpttVqFiYkJ6eulJp08Ho8AQAAgOJ3OkpOHamjWBJOWKAqry+USwuGwMD8\/r\/iNWiGsegipaH5+XvjvFou0Ruj1egWDwSCthU9MTAhWq3XR9y0MrNlsFgAsWq9VG8NaRVjNZrNgMBgEu90u+P1+2b9pWyGsepNKpYR1f3WB8PfnLBfsdrv0S2Z+fl6wWCxFv3QKPxYDG7ovJpjNZiEej6ve9oUYVoVhFcXjccHn8wl2u10wGAyC1WoVAoFAxe\/RSljj8bgQCAQEl8ul2b+UeipV5eTz+aS\/j1QqJbhcLgGA4PV6pec8sE8QevGcEHvkWdXbXArDWuU6q8VigcVigd1uRy6XQzweRyQS0cTZp5WEQiHMz89j48aNcDqdsFqtmjoGshEW7jTxoskEv9+PaDSKkZERBINBuFwumEwmDA0NSd+XX9Z5E75xmTZ3TWxHipZuLr\/8cqxYsQIWiwV+vx\/z8\/PS\/sF6KNIPBAJwOBwAgM7OTrhcrkU3bbeiwp0mvj40BLPZDKfTiVwuJx2H4vf7pbOA0uk0stmsZndNbFeKwhqNRpFKpeB0OuFyueByubB+\/XrdTOUvXP+1Wq2w2+2yvndubk5zt0wpIe408Ytg\/vjLYDCInTt3IhwOI5fLYf369chmsxgZGUFPT4\/0\/4mB1Q7FhymLNzknEgm43W50dHSgr68Pu3btalQb68blcmFiYgJA\/li\/XC4Hn89X8f7bUCiEDRs2wOfzwefzYXJyUqXW1t+5rrUI3+LD0b9+K1auXIlsNguv1wu\/34\/x8XFYLBZkMhkkEomidWMGViOqvdgVbyVyOp0CgEW3xC3UrAmmhYXYBoOhaAY7lUoJJpOpaIIsHo9LM6Aej0dIJpOCIAhCJpNp+hJGPZy44hPCiSs+IXg8HsFisQhWq1VwOp1CIpGo+H31vL1OKU4wKZxgCoVCiEajiEQiSKVSsNlscDqdGB4e1szeNQsPE1pYp+tyuRAIBKQyvK6uLgwPD2NiYgIbN27E2NiY1MPE43G43W4EAgHYbDZMTEzAZDJhZmZG12f7mI4cxPwnr8bP\/btgsffD6\/XKqmUurCW+dt\/pz0klSpJtMpkEl8slBAIB6VYrucr1rLUUGASDwUV\/lhKNRgWLxVL0WDKZFMxmsyAI+Z5U5HDkK4B6enqEcDgsCEJ+jVIry1C1+n3P+0reuL6U9DP5HvaBffKe\/+WrBOHzlxQ\/djGKH8ueyD\/2+I9KvwZ7VoU964kTJ+ryCyIUCiEYDCIcDi95HHylY\/eqqccV3ysWi0kf53I5aZZ45858Pe309LT0mNvtluppU6mUqsdCNNJ54XvwguUyACi7NUwpF67IL+dcc1H+86V62DVDwNYPnv78iYfz\/519\/PRjP3oQMAB43wdkN6PtqLIVaSgUQiaTwcDAwKJDauPxeN0DuRSXywWv1yudi5JKpeD3+4ueMzExIe1363K54Ha7pd3cm70Pbr0UrsECjQvs+z6QD+Khu\/LPe+QB4OKrgJ8eBH72JPCu9wLf+xbQr40dS7VLrS7c6XQKwWBQ8Hg8gs1mk4rDVWyCJJVKCQaDQchkMiXrnOPxuOD3+4VEIiENi7VQctcohTtNKCV3SLx9kyC4V+Y\/XgNBOHIgPwze+fXTQ+CfPlH++zkMrtNOEXINDg4W9ZShUKgpB9Z2dXXBZrMhEomU3HlP3NIzl8tJt\/ppZQKtEQqLJs5LPVLyPJ1y5PawA58Fhvbkl35+C+CSDwG\/fQ6Y3AJc+DfA65HvYakCtX4raG1SxufzCS6Xq+TXqrmrqBW8uD\/U0B72I8hPNl312r+6uefzPap7Zb6HFQRB+OUvBOGr6\/N\/fvmL09\/LnlXlnlVL7HZ70ZH0hTSxR2wTFB7PYbr\/HkXfK6eH\/dDXgQPfBNZ+Pf\/5X5kBE4DZGWD7a9Wqt38ZuOm+\/Meb7cDe1q8Gla1tw7pq1aqWHtpWS9xpYv6jV8F05KCi710qsFduAJ6OAh9wnn7sqp3ArxKnbxTY\/f3TX3vj25S3v5W1bVipPNORg\/nAfvLquvawF64Axh8rfv4GT+nX+dmTQN\/HFL11y+ORj1SS6chBCL9KL3nieiliYHevzy\/XKPWzJ4Ff\/jsrpBZiz0plVVs0ASgvnBA9fATInQQ+pe1bo5uCYaWyaimaAKoL7OS3gVN\/BA7enP+cE0ynMaxt4qXgARguX40zXpvp\/nM2i9zRqZKPFYZy4U4TStZgAeWBLZxgomK8Zm0Tp7bdipf+ZZ\/0+Uv3hXBq3Zi1tHsAACAASURBVD8VPfbit8dxatuti763sGjilSpuwK\/1GpbyGNY2scx9Ff50\/\/ekz1955DHg\/L\/EKw+fnp595cD3cNbQ1SW\/X9xpgoFtHoa1TZz7j+uBY09JQRMOPgxDaBeEh54EgPzjiaex\/FPlb5w417UWy27ZiD9++WtVtYGBrQ3D2ibO7OwE+npx8r4QTsWngfNNWO74MHC+CbloDCfvCwF9vfnnVXDeyPXAyRzmP3oVgPy1sJLlHQa2epxgaiNnf\/7TePmOuyHkcjjj4xcDADo+\/A94+dEYXn3whzh78+dkvY5YNHGi9xIg8XT+tRVMPpWbdHriYd7PWgl71jayfGANcCyJV+98AGddkd8r+exPfByv+vcDiV\/lv458b5n99GeQ\/fRn8KfZ2ZKvdfbVa6WgAsALztLXuuUs7GE39ADXf5C9bSUMaxs5w2hExxWrgOeewzmX5nfJOOfSfuAP\/4WOK94rLeEIuRyMd98J49134qWbdix6nZeCB3Bq3T8VP5h4WnG1kxjYW9fni\/mBfHi5g2JpDGubed1tN8Nw9D7p2vTMzk4Yjt6H19128+nnuK\/Bn2Zn8YdtN+KczyxeGM3PDH970eOn1o0obs+2geLPXy7xGOUxrG3mrO7u\/MRSgeWOD+Os7u6ix84wmXBWnw0vPxor+TrnutZi+aMPACi8nTCL7LXXKWrPiZnFj83OcDhcCsNKi5yKT+PMzk4sd3wYf\/6PX5Z9nsHej\/NSj6AwsH++fR9y0dIBLyUsnL6\/tdCtHA4vwrDSIqcOPYgXJ+7CH\/fcgTPf+d8rPndZVxfeIPwnOq6wS4+d3HKDovfz3AgEnwHOXvD4tRcpepmWx7DSIufvuBnLrN04q3dlfl1VBtORg1h2y2vPTTyNF0YXT0xVcuEKICoAlxZsifVbAP5vKHqZlsawUknn2FbhHJuynTTOG7lemnh65avjVZUl3jwB7PjR6V72wDdP7zPc7hhWqqtzXWtxXur\/AABevG13Va\/xvg\/kl3S6Xzuh5IYPVn5+u1CtgimTyVTczJtay6nNH8exXbtgf+97qn4Nxwjwjtn34eC2N+PI7kvQgP3edUW1sJrN5obsrk\/adML1VfwJZ9X8d\/41N3ACP8bmHRfXp2E6xmEw1V1+cimLMz9+eU2v88TDwKP7gJfxPDcAB8NKdfZKOo1XvpqfCT5jhbJdJRa69bVr1XetFmptVktgWKmu\/viF0xVM5\/TZqn4d\/zfySzcA8Ja3MawAw0p19FLwAISHovlPet5e9es8ezy\/ZCN69\/v+XFvDWgTDSnVTWMjf8ebKN7FXUli51K3fA+brjmFtQy9O3IUT3e\/BiY434kTvJfmdI2qUL+DPSp+ffbWybUtFh+46PfwFgJUfr61drYRhbTMvBQ\/g5Q1bcabrozhn\/7fR8RdGvNR3Ff6czS79zWW8kk7jz7fvK3rsDLPynvXZ4\/n7WQtd+DdVN6vlMKxt5tTu7+DMr\/wjzt\/+DZzrWovzD92LZbd8EUIuV\/VrltolwmDvV\/w62wby97MW4hEapzGs7ebYv2PZO09fCJ5hNOK8keuX3CitnFw0VrS9C4CqJ5fe1FN8581fVfUqrYthbUO19KILGez9eIPwu9N33KD6yaWbJ4CbfgS845J8aP9u8aH0bY27G7abvr\/Hq\/9RvAna\/CevxllXfBjLB9bg1LFpnNO3StqPSa4zV1hw5v5v4wxzJ5atsFTdvKN3A1\/bd\/q8VjqNYW0z51z7OZxatxl\/ALDsnSvxpx9PQzj4MM78wufwwv\/8Es66YjX+8Nkv4Lz\/fZuiofHL9xxQfPjyQuLOEAxqaQxrmxEPnTq17Va8+r\/GgZ63w3B0H87u7cGymyxY1tUFIZfDy0\/NLNqrqdEO7QUG5G1d3JYY1jZ0rmttyeMbzzAa8cc9d+CVh36gqJd8KXig6nXVQjMP5rd4odI4wURFXr\/p8zj3pq\/jD9vkp+blew4oPrt1oSceBlbxDsqKGFYCkC9sOBn5AQBg2QoLhBPyiiReSafRcVFtd9cAwJ3XAUPKtx1uKxwGE4D8LoUv\/fMdePneEPAGE17\/NXkbpZ28LwTDp2rrVZ89nl9jpcoYVpKcv+PmpZ+0wKtP\/gTnyNwBsZzx7cDGbTW9RFvgMJiqlovGsOwD76\/6+\/f6gWs\/AiT2AadO1rFhLYo9K1Xt1KEH8brrrq3qe50dwDyA1wH4A4B\/\/DvgX34BvO2\/1bOFrYU9K1VNeCYt+0zWQg\/dD\/z\/yG83+teXAI8LwIVvAX76eP3b2ErYs1JVahkC\/\/ihfDh\/+xvg7fb8Y\/c+W7+2tSqGlaqSu\/X2qssLf5MAXm8BDn+HE0tKcBhMqrN+EPj94\/nQinXAP3sSuG+8ue3SOoaVFKu1vPAjnwKeQz60APDbDHDT+4DYvcD\/\/Y\/8DPG1H8lv8E2ncRhMitV6h8073gmcB+DB24DJ2\/KPvQH5W+N+9jiw+\/v5x\/b6gYeP1NzclsGwkiL1KC984mFg4BbgU5uAx38IdL4J0o77hbfHnToJvO3vgN\/9pKa3axkMKylSj\/LCO68D9ibyH1\/xydLP+bd\/Bc7\/i3x4jzGsAHjNSgq9+uRPFJ\/bWkhOHfATDwP\/9lPgUxurfpuWxLCSbPUYAi91g\/nDR4DJAGBYnt9DWNw9ghhWUuDF23ZXXV4omnkQFU+EM74B6PtYTW\/RsnjNSrJVW14oOnQX8LEvVX7Ou967OMy8Zs1jWEmWWu+wAYDvfev0xBIpx2EwyXLq0IMwXLmm6u\/nDea1Y1hJllqHwLzBvHYMKy2pHrsXFtYBU3V4zUpLqrW80P8N4Av\/XMcGtSn2rFRRPdZWl1quIXkYVqqo1vJC7gdcPwwrVVRreeHd27kfcL0wrFRWPYbAb7yoTo0hhpXKq7W8MP3MGTxoqo4YViqr1rXVu756BieW6ohhpZJqLS984mGg82\/r2CBiWKm0WssL77wO+PyNr9SxRcSwUkm1DIFZB9wYDCstUmt5IeuAG4NhpUVqPRyZdcCNwbBSXbEOuHEYVirywugOLL\/hK1V\/P+uAG4dhpSK1lBeyDrixGFaS1FpeePRu4COuOjaIijCsJKnlDhtxy1BOLDUOw0qSWobAS+0HTLVjWAlA7eWFnFhqvJrDOjIygi1btiCdTkuPjY2N1fqypLJaygs5saSOmsI6NjYGp9OJnTt3IhKJYGZmBgAQj8fr0jhSTy3lhXdexxvM1VBTWJPJJFatyl\/jbNy4EclkErOzs3VpGKmnlvJC1gGrp6awOp1OjIyc\/pU6ODiIRCIBg8FQc8NIPbWUF7IOWD01bUW6Zs0aWK3WoscGBwfR08Nfte2CdcDqqXnf4O7ubgwMDAAADAYDcrkcbDYbtm7dWnPjqPFqGQLLOWiK6qcum3wfPnxY+nhmZgapVKoeL0sqqGUDbx40pa66r7OaTCZEIpF6vyw1QC3lhVyuUV9detbCYbDZbMbw8HA9XpYarJbywqN3c2JJbTWFdXZ2Ft3d3UXDYNKPV5\/8Cc4Zub6q7+XEkvpkD4Onp6fR29uLbDYLIB9Uq9WKdevWNaxx1Di1lBfyBvPmkBXWbDYLh8MBq9WKXC4HID8LHI\/HEYlEsG\/fvoY2kuqvlvJC1gE3h6ywRqNRzM\/PY\/\/+\/ejs7JQeX7VqFex2O6LRaKPaRw1SbXkhJ5aaR1ZYLRYLABQV64symYz0ddKHWobArANuHlkTTCtXroTNZoPD4YDH44HJZEIul0M4HEYymUQwGGx0O6mOcrfeXtXaKuuAm0v2bHAkEoHX60UgEEAikYDZbIbNZkM0GkVXDeehkH7wBvPmkh1Wo9GInTt3NrItpIJaygtnHgQ8N9a5QSRbXYoiSD+qLS9kHXDzyQ6rWKV0+PDhoo9JP2opL2QdcPMpqg0uvE+V96zqT7XlhZxY0gZumNZGqt29kDeYawPD2iZqGQKzDlgbGNY28eJtu\/G6665V\/H2sA9YOhrVNVFteyDpg7ZA9G2yz2aRJpcKPSfuqLS9kHbC2yA5r4Z5K5fZXmpqagtVqZUWTxpw69GBVQ+A7r+NyjZbUVBQxMzMDn88Hg8EAk8mEnp4exONxOBwOaT9har5qhsBcrtGemsIaCASwf\/9+ZLNZ+Hw+rF+\/HgCwYcMGhlUjqi0vZB2w9tQ0wWSxWDA9PQ2j0YihoSEA+R0lbDZbXRpHtat2A29OLGlPTWHdunWrdK6NeJ0ajUaxcePG2ltGNat2bZUTS9pUcyH\/5s2bEQqFpM8tFgtisRj6+\/trfWmqUbXlhZxY0qa6r7Mmk0lu8q0R1ZQXcmJJu+pyi9zgYPGYacOGDdJkEzVHtUNg1gFrV903+QYAt9tdj5elGlQ7BGYdsHbV\/awb0oZqNvBmHbC2yb5mzWazGBsbkz6fm5tDb29v0eQSaUO15YVcrtE22WF1OBzw+\/1F25Ha7Xa4XC5MT083pHFUnWo28OZyjfbJCuv09DTi8Tji8bi0ntrZ2YmdO3fCbrdzK1KNqaa88OjdwEdcDWoQ1YWssM7PzwNAyQJ98QBl0oZqygufPZ7\/LyeWtE1WWG02G0wmEzZt2oS5uTkA+WvYUCiEaDQKl4u\/krWimvJC1gHrg6ywGo1GRCIRRCIRmM1mdHR0wGQywe12w+fzsVpJ5zixpA+yl25WrVqF48ePY3Z2VtqRv6enB0ajsZHtIwVeGN2B5Td8RdH3cGJJPxSvs3Z3d6O7u7sRbaEaVbO2yjpg\/eAeTC2imvJC1gGXZjabm92Eknh8RouopryQdcCllZqDSafT0g0qJpMJK1euVLlV7FlbRjV32LAOWL5EIoH+\/n709\/dLS5lqY1hbQDXlhTxoShmTyYTx8XHMzc3BarU2pQ0Mawuoprzwe98CrrymQQ1qQf39\/bBYLPD7\/U27X5thbQFKywu5XKPc1NQUVq9ejdHRUWQymaa0gRNMOlfNEPjo3ZxYUspmsyEWiyGXy6GnpzlT6AyrzuVuvV3x4cicWFLOaDQ2vVKPw+A2wxvM62NsbAyTk5PIZrOqvSd7Vh2r5g6bmQcBz40NalAbKXeETCOxZ9UxpXfYcGKpOps2bcKGDRswNjYm9aTivmNqYs+qU9WUF7IOWLnp6Wn09PRg48aNyGazmJiYgNvtbsopiuxZdUppeSHrgGtnNBqxefNmTExMNGXDBYZVp5SWF\/IG8+qsWrUKyWSyaJ8xt9vdlJJDDoN1qJq1VU4sVW\/nzp1FnxuNRjz66KOqt4Nh1SGlhyOzDrh2Y2NjiMfjMBgMmJ+fx\/z8PI4dO6ZqGxhWHVJaXvi9b3FiqVYLl2q2bNmiehsYVp1ROgTmxFJ9xGIxqSY4l8s1pT6YYdUZpeWFvMG8\/kwmEwKBgOrvy7C2ONYBK5dOp6U9sqenp5FMJjVxKiKXbnREaXkh64CVyWaz6Ovrg9PplB5LJpPweDxYt25dE1uWx7DqiNLyQu4HrEwgEEAmk0E4HJYeW79+PSKRCILBIGZnZ5vYOoZVN5SWF7IOWLl4PI6enp5Fx8SsWpUvPkkmk81oloRh1Qml5YV3XgcMjTSwQS3IbrcjkUhIR8SIJicnYTAYYLPZmtSyPE4w6YSSDby5XFMdt9uNYDAIq9Uqne+UyWQQjUbh8\/nQ2dnZ1PaxZ9UBpUNg1gFXx2g04tixYwgEArBarcjlcnA4HIjH4025f3Uh9qw68OJtuxWVF7IOuDY2mw2Dg9q74GfPqgNKygs5sVS7eDze7CaUxJ5V45SWF\/IG89bFnlXjlGzgzYml1sawapySITDrgFsbw6phSssLWQfc2njNqmEv33NA9h02rANufexZNUrp2irrgFsfw6pRSsoLuVzTHhhWjVKye+HRu4GPuBrcIGo6hlWDlAyBnz2e\/y8nllofw6pBSobArANuHwyrBikZAnNiqX0wrBqjpLyQE0vtheusGqNkA2\/WAbcX9qwaI7e8kHXA7Ydh1RAl5YWsA24\/HAZriJLyQtYBtx\/2rDrEg6baE3tWjXhhdAeW3\/AVWc\/lQVPtiT2rRshdW+VyTftiWDVASXkh64DbF8OqAUrKCzmx1L4YVg2QOwTmDebtjWFtMiXlhawDbm8Ma5PJ3b2QE0vEpZsmk1teyDpgYs\/aRHKHwKwDJoA9a1Plbr1dVnkhbzAngD2rLnBiiQCGtWnk3mHDOmAScRjcJHLvsGEdMInYszaB3PJCTixRIYa1CeSWF\/IGcyrEsDaB3PJC1gFTIYZVZXLXVlkHTAsxrCqTW17I5RpaiGFVmZzyQtYBUylculGR3CEw64CpFIZVRXLKC7lcQ+VwGKwxrAOmchhWlcgtL+TEEpXDYbBK5JQXcmKJKmFYVSC3vJATS1QJh8EqkFNeyIklWgrDqgI55YWsA6alMKwNJncIzDpgWgrD2mAv3rZ7ycORWQdMcjCsDSanvJDLNSQHw9pAcsoLuVxDcjGsDSTnDhseNEVyMawNtNQQ+Nnj+f9yYonkYFgbRE55IeuASQmGtUFevucAznVVDisnlkgJhrVJOLFESrE2uAFeGN2B5Td8peJzWAdMSrFnbYClygtZB0zVYFjrTE55IeuAqRoMa53JucOGdcBUDYa1zpYaAvOgKaoWJ5jqSE55IQ+aomqxZ62jpcoLuVxDtWBY62ip8kLWAVMtGNY6kVNeyIklqgWvWetkqd0LeYM51Yo9q0pYB0y1YljrYKnyQk4sUT0wrHWw1NrqndcBQyMqNohaEsNao6XKC1kHTPXCsNZoqfJC3mBO9cKw1mipITAnlqheGNYaLFVeyDpgqieGtQZLlRd+71vAldeo2CBqaQxrDSqVF3JiieqNYa3SUkNg3mBO9cZywyrlbr29Ynkh64Cp3tizNgDrgKkRGNYqLHWHDZdrqBE4DK5CpTtsWAdMjcKwKrRUeSH3A6ZG4TBYoUrlhVyuoUZiWBWqVF7IOmBqJIZVgaXWVjmxRI3EsCpQqbyQE0vUaJxgUqBSeSEnlqjR2LPKVGkIzIklUgPDKlOlITDrgEkNDKtMlYbArAMmNTCsMlQqL2QdMKmFYZXh5XsO4FxX6bByuYbUwrAuoVJ5IZdrSE0M6xIqlRfyoClSE8O6hHLlhc8ez\/+XE0ukFoa1gkpDYNYBk9oY1gpevG03XnfdtSW\/xoklUhvDWkG5tVVOLFEzsDa4jErlhawDpmZgz1pGufJC1gFTszCsZZQbArMOmJqFYS2hUnkh64CpWXjNWkK53Qt50BQ1E8OqwPe+xYklah4Ogxd4YXQHlt\/wlUWPc7mGmo1hXaBceSHrgKnZGNYClcoLObFEzcawFih3hw1vMCctYFgLlBsCsw6YtIBhfU258kJOLJFWcOnmNacOPVjyDhvWAZNWsGd9TanyQtYBk5YwrChfXsgbzElLGFaU372QE0ukJQxrGd+68TnWAZOmqD7BlE6nEY\/HpT9msxmHDx9WuxmScuWF\/3bozfgSJ5ZIQ1QLayaTwQUXXIBMJlP0uM1mQygUkj43m83o7+9Xq1n5tdWR64see+zRX+NNPW9RrQ1EcqgWVrPZjGAwiGAwCL\/fL4XW4\/FgcPD0QmY6nUYoFILZbIbVaoXH44HVaoXZbIbdbkd3dzfm5ubQ2dlZc5vKlRd+54YzcfM9Nb88UV2pOgzu6urC1q1bsXXrVoRCIfj9\/pLP6XptCaW3txdDQ0PYuHEjAGB8fBxAvjdOpVIwGo01tadUeWE6nca5Z3axDpg0p2kTTIODgzh27FhRr1ooFoshkUjA5Tp9q4vBYIDH44HH4ykb1FgsJrsNpcoLD9\/Zhc+Nyn4JItVotoIpkUjAZrMVhdJqtSIajSIYDJb9PovFsuQ1cDqdRufxVMnywh9+8zfw3PimOvwERPWl2bCaTCaYTKaix\/x+P4aHhysOfwuH0cDpa2DgdHBtNhtuyi3D+sQTRd978N7\/Dx\/6+l\/X8acgqh\/NhtXpdBZd005OTiKRSMDhcBQ9b6nJpsLwptNpjI2NvTa5ZcBbbDbE43Hp63uvPgMPCfX\/WYjqQbNhNRqNCAQCGBsbg8lkQiKRQCQSgd\/vl2aKE4kEUqkUotGorLXarq4uWCwW\/AM68DP8CZlMBhaLBcFgEH3vGUTPeg5\/Sbs0G1YAWLVqFVatKp4AstvtmJ+fL+oxo9EostmsrNnhVCoF7+v\/Gnd+8B\/gMhiQy+UQDAZxxzeWYfu3P9GQn4OoHjQd1lLWrFm8S77dbpe9jLN161bMP\/5TfPRw8VajV3T8Bu\/7QF2aSNQQuq8NnpqawubNm2U\/v9QdNrfe\/Dg+9HUOgUnbdNezitLpNObn57F69WpF31dqA+9f3H8JbzAnzdNtzxqPxxEMBjEyMoKpqSlZ31OqvDBfB9yIFhLVl2571sHBwbLVT+WUKi9kHTDphW571mosLC9Mp9P4\/Y+5HzDpg257VqVK7V54+M4ubH+izDcQaUzb9KylDkf+4Td\/w21bSDfaJqwLdy\/M1wFzuYb0oy3CWmoIfMdIGlduaFKDiKrQFmFdOAR+9jjw7svey4kl0pW2COvCIfC3R5\/D5Z9uYoOIqtDyYS1VXvhv3+lgHTDpTsuHdeEG3qwDJr1q6XXWUuWFj97wVt5gTrrU0j3rwvLCxx79NW8wJ91q6bAuLC\/8zg1nYuO2JjaIqAYtG9aFQ2DWAZPetWxYX7xtd9HhyA\/sW4bP7OMQmPSrZSeYFq6tPrytgxNLpGst2bMuLC9kHTC1gpYM68LyQtYBUytoybAWDoHT6TTe\/BesAyb9a7mwLiwv3HPzMnzmtiY2iKhOWi6sC8sLWQdMraLlwlqIdcDUSlpq6eaF0R1YfsNXpM9ZB0ytpKV61sLyQtYBU6tpmbAuLC\/cc9OzGPhcExtEVGctE9bCO2zS6TT+8MgK7lxILaVlwlo4BGYdMLWilphgWlheyDpgakUt0bMWlhce2P8YJ5aoJbVEz1pYXvjdrWfiu7EmN4ioAXTfsxaWF7IOmFqZ7nvWwsORWQdMrUz3PWuhqe+kWQdMLUvXYS0cAt968+PYeMvFTW4RUePoehhcOARmHTC1Ot32rIXlhawDpnag27AWlhd+f\/8ZPGiKWp5uwyqWF6bTad5gTm1Bl2EtLC+8\/55neYM5tQVdTjCdOvSgtIE3J5aoXeiyZxXLCzmxRO1Edz1r4RD4pvXP4ruxtzS5RUTq0F9Yb70dpiMHkU6ncdavV7AOmNqGLofBQL4OeORHHAJT+9BVWAvLC7lcQ+1GV2EVN\/DmfsDUjnRzzVpYXviD8TN4gzm1Hd30rGJ54WOP\/hrvvow3mFP70U1YxfJC1gFTu9JFWMUhMOuAqZ3pIqwv3rYbr7vuWtYBU1vTxQSTWF547w3P4SnWAVOb0nzPKpYXPvbor\/GR9dy2hdqX5ntW8Q6bmy5hHTC1N833rMIzaTwHsA6Y2p6mwyqWF\/7z2K950BS1PU2HVSwv\/MWei3DlNc1uDVFzaTas4toq64CJ8jQ7wSSWF\/5g7SusAyaChnvWV5\/8CRId4EFTRK\/RZFjFIfDhO\/+aB00RvUaTYX3xtt343Sc+zjpgogKaDKvwTBqHnziDE0tEBTQ3wSSWF977pTNZB0xUQHM966lDD+Kn5h7WARMtoLmwCs+kcZP3v3iDOdECmgrrS8EDeP5974Hhl32cWCJaQFNhffmeA9j77MWsAyYqQVNhBcA6YKIyNBPWF0Z34PYzunjQFFEZmlm6efXJn+Dxn29hHTBRGZroWV9Jp\/Hk3POsAyaqQBM968n7Qvhh9kv4wt5mt4RIuzTRsx4\/+CBi\/\/cCvOu9zW4JkXY1Pay5aAyHnjZj4y2sWCKqpOnD4FOHHsT9J9fhFyPNbgmRtjW9Z338jp\/Auf4TzW4GkeY1NawvBQ\/gjlOrWAdMJENTh8Ev33MAr2I364CJZGhqz3rooQxvMCeSqWk960vBA4hgBw7c2KwWEOlL03rW\/xw7gLfxBnMi2ZrSs76STmM80YfrDzXj3Yn0qSk968n7QjiBdawDJlKgKWHd\/S9vxaYfcWKJSAnVw5qLxjDzqwu4XEOkkOrXrLH7\/wuX3XKV2m9LtKR0Oo14PI54PA4AMJvN6O\/vb3KrTlM9rN\/\/dgeue0btdyWSx+VySR\/7fD5NhVXVYfAzj\/4ar1\/\/CU4skSZ1dXXBZrNJnxd+rAWqhjX0zWcx8Dk135FIGafTCUB7Q2BA5bD++6MreIM5aZo4DNZarwqoGNZ4+Ld4N+uASePEoXDhtatWqDbBtPyMPniWqAMWZ+OoNdTr71LtfxNmsxmpVAqhUEjW8wcHBxvcojzVwjp637uXfE5XVxe6urpUaA2ppV7\/kNUKhNrvpUTTd4ogInkYViKdYFiJdIJhJdIJhpVIJxhWIp1gWIl0gmEl0gmGlUgnGFYinWBYiXSCYSXSCYaVSCcYViKdYFiJdIJhJdIJhpVIJxhWIp1gWIl0gmEl0gmGlUgnGFYinWh6WGOxWLObUBezs7MIhUKYm5trdlNUl06nkU6nm92Mlqd6WGOxGLZs2YK+vj50dHTA7\/er3YS6ymazuPzyy2G1WuFyuWA2mzE2NtbsZqkqHo\/DYrHgggsuwMDAgOzNsUkZ1Tb5TqVS6OjoWPR4JpPR7V+uzWZDIBBAMplEMplEd3c3du3aBY\/HA5fLpWjD8lgshkwm08DWNo64Y34mk0E4HEY4HIbL5YLNZtPshtl6pFpYLRYLBEFAKBRCMBhEOBwGkD+qQM9\/oZFIBB6PB93d3QCAzZs3w+FwKD5ZQGsnllXLZrPB6XTC5XLxKJQ6U\/0w5cHBQSmcoVAIqVRK7SbUVSKRgNlsLnpMDG67MJvN8Pl8i0YTDGt9qR7WQnruUUVmsxm5XK7osXQ63VZn9vT397fMyEDLmj4brHd2ux3BYFD6PJvNwm63LznJNDs7iy1btmD79u2NbiK1CIa1Rl6vF\/F4HG9\/+9sxMDCAnp4eGAwGDA0NVfw+v9+P39qqSQAAA01JREFUnTt3wul0YmRkRKXWkp41dRjcCrq7u5FMJjExMYFEIgGPxwO32w2j0SiFN5FIoKenB\/Pz80ilUpiYmMCePXuk1zCZTE38CUgvGNY66OzsxNatW0t+zePxwGg04vLLL8fRo0exb98+RKNRrFmzBrFYDOFwGDabTeUWkx5xGNxgRqMRAGAwGKT\/ihNS\/f392Llzp7SM1WpaYQJRSxjWJtmwYQOy2Syy2eyipR+iUjgMbqDC4a34sdlshsFggNfrhdfrhcFgwPDwcLOaSDrSIQiCoMYbhUIhDouoKvy3k8dhMJFOMKxEOsGwEukEw0qkEwwrkU4wrEQ6wbAS6QTDSqQTDCuRTjCsRDrBsBLpBMNKpBMMK5FOMKxEOsGwEukEw0qkEwwrkU40LazpdBqhUKhtTlxLp9MYGxvDwMAAdu3a1ezmaFIsFsPY2Bimp6eb3RRNUnUPplAohHg8jmAwKJ2Y5nQ61WxCU8zMzMBut8NsNsNqtcLr9SIYDOLYsWPNbpqmZDKZov2oxAOu9H4eUr2oeuRjPB5HPB4vOtpQz0c+ymGz2eDz+WC323H48GEA+fAODQ0pPhMnnU639GFPC382cYtWcRvXdqfqkY\/iRtjpdBrBYBDxeBwGg6HlN8OKRqPw+XzS5ytXrqyqV+3q6mr5A69sNpt0bKR42FUr\/zJXoilbkXZ1dZXdwb4VZTIZ9g4yFB4HSotxNlgFPT09i04137dvn6yJlOnpaU64EACGVRUOhwN+vx8zMzMA8rOeQ0NDS06cbNmyBYlEAolEAlu2bFGhpaRl3JFfBcPDw0gmk+jp6ZEe83g8GBwcxNjYGKxWK8LhMDwej3TW6+joKFwuF1atWgUAWLduXVPaTtrBsKrAaDTi8OHDmJ2dRSKRgM1mkyaK4vE47HY7fD4fHA4HnnrqKezatQuxWEyaYMlms7Barc38EUgDVAsrD1\/Kn+Xa3d296HGx97RYLADy\/6\/Ea9xsNgu\/349t27ap1k6t4b+dPNXCKvYSJJ+4xOXxeJrdlKbiv508DoM1zO12w2QyIZFIIJfLSUUV1J5UO0WOiGrDpRsinWBYiXSCYSXSCYaVSCcYViKdYFiJdIJhJdIJhpVIJxhWIp34f5ip+Lk57rJyAAAAAElFTkSuQmCC","width":187}
%---
%[output:06c7bdb7]
%   data: {"dataType":"text","outputData":{"text":"==================== PUMP METRICS ====================\n","truncated":false}}
%---
%[output:75f9be99]
%   data: {"dataType":"text","outputData":{"text":"Pressure Rise       : 76.26 bar\n","truncated":false}}
%---
%[output:060a8d27]
%   data: {"dataType":"text","outputData":{"text":"Shaft Torque        : 20.14 Nm\n","truncated":false}}
%---
%[output:8b29d7ad]
%   data: {"dataType":"text","outputData":{"text":"Hydraulic Efficiency: 50.41 ","truncated":false}}
%---
%[output:8c3bde89]
%   data: {"dataType":"text","outputData":{"text":"Axial Thrust Force  : 2242.59 N\n","truncated":false}}
%---
%[output:71fcca51]
%   data: {"dataType":"text","outputData":{"text":"================ CALCULATED ANGLES ===================\n","truncated":false}}
%---
%[output:0e1532fb]
%   data: {"dataType":"text","outputData":{"text":"Inlet Blade Angle (Beta 1) : 13.04 deg\n","truncated":false}}
%---
%[output:129fe68c]
%   data: {"dataType":"text","outputData":{"text":"Outlet Blade Angle (Beta 2): 23.47 deg\n","truncated":false}}
%---
%[output:6ea0a3f2]
%   data: {"dataType":"text","outputData":{"text":"Flow Deviation Angle       : 14.44 deg\n","truncated":false}}
%---
%[output:934e023a]
%   data: {"dataType":"text","outputData":{"text":"============== INDUCER STAGE RESULTS =================\n","truncated":false}}
%---
%[output:2e157e9b]
%   data: {"dataType":"text","outputData":{"text":"Inducer Axial Velocity (Cz): 7.70 m\/s\n","truncated":false}}
%---
%[output:45809bf1]
%   data: {"dataType":"text","outputData":{"text":"Inducer Tip Speed (Utip)   : 48.38 m\/s\n","truncated":false}}
%---
%[output:4fa87db3]
%   data: {"dataType":"text","outputData":{"text":"Inducer Pressure Rise      : 4.81 bar\n\n","truncated":false}}
%---
%[output:04fa2479]
%   data: {"dataType":"text","outputData":{"text":"============== NASA SP-8109 SCREENING ================\n","truncated":false}}
%---
%[output:8a18d20f]
%   data: {"dataType":"text","outputData":{"text":"Non-Dim Specific Speed (Ns): 0.277\n","truncated":false}}
%---
%[output:8be8a566]
%   data: {"dataType":"text","outputData":{"text":"Non-Dim Specific Dia   (Ds): 10.641 (Optimum: 9.329)\n","truncated":false}}
%---
%[output:4a7bb452]
%   data: {"dataType":"text","outputData":{"text":"Ds Ratio (Ds \/ Ds_opt)    : 1.14\n","truncated":false}}
%---
%[output:53c7ced2]
%   data: {"dataType":"text","outputData":{"text":"NASA SP-8109 Viability      : PASS (Geometry sits near Cordier optimum)\n","truncated":false}}
%---
%[output:87640fc7]
%   data: {"dataType":"text","outputData":{"text":"================ CAVITATION CHECK ====================\n","truncated":false}}
%---
%[output:294ccd96]
%   data: {"dataType":"text","outputData":{"text":"NPSH Available : 81.87 m\n","truncated":false}}
%---
%[output:0a179b13]
%   data: {"dataType":"text","outputData":{"text":"NPSH Required  : 4.50 m\n","truncated":false}}
%---
%[output:7d2027c8]
%   data: {"dataType":"text","outputData":{"text":"NPSH Margin    : 77.37 m\n","truncated":false}}
%---
%[output:91bce2b8]
%   data: {"dataType":"text","outputData":{"text":"Cavitation Status: PASS: NPSH_available > NPSH_required.\n","truncated":false}}
%---
%[output:814b7237]
%   data: {"dataType":"text","outputData":{"text":"=================== RUN TIME =========================\n","truncated":false}}
%---
%[output:8b66469f]
%   data: {"dataType":"text","outputData":{"text":"Execution Time : 0.0327 seconds\n","truncated":false}}
%---
