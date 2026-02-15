%% INSULIN REACTOR - FIXED IoT VERSION
% Real-time updates with precise temperature and pH display

clear; clc;
global RUNNING;
RUNNING = false;

%% --- Create UI Figure ---
f = figure(...
    'Name','Insulin Reactor Dashboard',...
    'NumberTitle','off',...
    'Color',[0.95 0.95 0.95],...
    'Position',[100 100 1300 750]);

%% --- Header ---
annotation('textbox',[0 0.94 1 0.06],...
    'String','Insulin Reactor Control Panel',...
    'FontSize',22,'FontWeight','bold',...
    'HorizontalAlignment','center',...
    'VerticalAlignment','middle',...
    'BackgroundColor',[0.95 0.95 0.95],...
    'Color',[0.2 0.2 0.2],...
    'EdgeColor','none');

%% --- Reactor Visualization ---
subplot('Position',[0.05 0.50 0.30 0.38]);
if exist('reactor.png','file')
    reactorImg = imread('reactor.png');
    imshow(reactorImg);
else
    text(0.5,0.5,'REACTOR','FontSize',24,'HorizontalAlignment','center');
    axis off;
end
title('Reactor System','FontSize',14,'FontWeight','bold','Color',[0.2 0.2 0.2]);

%% --- INITIAL PARAMETERS ---
params.agit_rpm = 300;
params.T_set = 37;
params.pH_opt = 7.0;
params.mu_opt = 0.4;
params.Xmax = 10;
params.Yxs = 0.5;
params.alpha = 0.05;
params.beta = 0.01;
params.T_opt = 37;
params.k_heat = 0.02;
params.k_cool = 0.1;
params.k_acid = 0.005;
params.k_base = 0.01;
params.mu_var_scale = 0.05;
params.T_noise_scale = 0.05;
params.pH_noise_scale = 0.01;

params.ph_down = 0;
params.ph_up = 0;
params.temp_down = 0;

params.ph_down_timer = 0;
params.ph_up_timer = 0;
params.temp_down_timer = 0;

assignin('base','params',params);

%% --- RUN / STOP BUTTONS ---
uicontrol('Style','pushbutton','String','▶ RUN',...
    'FontSize',14,'FontWeight','bold',...
    'BackgroundColor',[0.3 0.75 0.3],'ForegroundColor','white',...
    'Units','normalized','Position',[0.08 0.42 0.10 0.05],...
    'Callback',@startSimulation);

uicontrol('Style','pushbutton','String','■ STOP',...
    'FontSize',14,'FontWeight','bold',...
    'BackgroundColor',[0.85 0.25 0.25],'ForegroundColor','white',...
    'Units','normalized','Position',[0.20 0.42 0.10 0.05],...
    'Callback',@stopSimulation);

%% --- PERTURB BUTTON ---
uicontrol('Style','pushbutton','String','Perturb',...
    'FontSize',11,'FontWeight','bold',...
    'BackgroundColor',[0.9 0.7 0.2],'ForegroundColor','black',...
    'Units','normalized','Position',[0.08 0.35 0.10 0.04],...
    'Callback',@perturbMenu);

%% --- OPEN IoT DASHBOARD BUTTON ---
uicontrol('Style','pushbutton','String','📡 IoT Dashboard',...
    'FontSize',11,'FontWeight','bold',...
    'BackgroundColor',[0.2 0.6 0.9],'ForegroundColor','white',...
    'Units','normalized','Position',[0.20 0.35 0.12 0.04],...
    'Callback',@openDashboard);

%% --- Batch Health display ---
healthText = uicontrol('Style','text',...
    'String','Batch Health: 100 %',...
    'FontSize',13,'FontWeight','bold',...
    'BackgroundColor',[0.95 0.95 0.95],'ForegroundColor',[0.0 0.5 0.0],...
    'Units','normalized','Position',[0.42 0.46 0.25 0.04],...
    'HorizontalAlignment','left');

%% --- AI Prediction display ---
predText = uicontrol('Style','text',...
    'String','AI Predicted Health (1h): --- %',...
    'FontSize',13,'FontWeight','bold',...
    'BackgroundColor',[0.95 0.95 0.95],'ForegroundColor',[0.5 0.0 0.8],...
    'Units','normalized','Position',[0.42 0.41 0.35 0.04],...
    'HorizontalAlignment','left');

%% --- RPM TEXT + +/- BUTTONS ---
rpmText = uicontrol('Style','text',...
    'String',sprintf('Agitation: %d RPM',params.agit_rpm),...
    'FontSize',12,'FontWeight','bold',...
    'BackgroundColor',[0.95 0.95 0.95],'ForegroundColor',[0.2 0.2 0.2],...
    'Units','normalized','Position',[0.42 0.36 0.20 0.04],...
    'HorizontalAlignment','left');

uicontrol('Style','pushbutton','String','RPM +',...
    'FontSize',11,'FontWeight','bold','BackgroundColor',[0.6 0.8 1],...
    'Units','normalized','Position',[0.63 0.36 0.07 0.04],...
    'Callback',@(src,evt) adjustRPM(+20));

uicontrol('Style','pushbutton','String','RPM -',...
    'FontSize',11,'FontWeight','bold','BackgroundColor',[0.6 0.8 1],...
    'Units','normalized','Position',[0.71 0.36 0.07 0.04],...
    'Callback',@(src,evt) adjustRPM(-20));

assignin('base','rpmText',rpmText);

%% --- STATUS MESSAGE ---
statusMsg = uicontrol('Style','text',...
    'String','Status: Normal',...
    'FontSize',13,'FontWeight','bold',...
    'BackgroundColor',[0.95 0.95 0.95],'ForegroundColor',[0.1 0.5 0.1],...
    'Units','normalized','Position',[0.75 0.92 0.22 0.05],...
    'HorizontalAlignment','center');

assignin('base','statusMsg',statusMsg);

%% --- PLOTS ---
ax1 = subplot('Position',[0.42 0.72 0.53 0.15]); hold on; grid on; box on;
title('Temperature'); ylabel('°C'); xlabel('Time (h)');

ax2 = subplot('Position',[0.42 0.50 0.53 0.15]); hold on; grid on; box on;
title('pH'); ylabel('pH'); xlabel('Time (h)');

ax3 = subplot('Position',[0.05 0.12 0.42 0.22]); hold on; grid on; box on;
title('Biomass'); xlabel('Time (h)'); ylabel('g/L');

ax4 = subplot('Position',[0.53 0.12 0.42 0.22]); hold on; grid on; box on;
title('Insulin'); xlabel('Time (h)'); ylabel('g/L');

assignin('base','ax1',ax1);
assignin('base','ax2',ax2);
assignin('base','ax3',ax3);
assignin('base','ax4',ax4);
assignin('base','healthText',healthText);
assignin('base','predText',predText);

%% --- CALLBACKS ---

function adjustRPM(delta)
    params = evalin('base','params');
    rpmText = evalin('base','rpmText');
    statusMsg = evalin('base','statusMsg');

    params.agit_rpm = max(100,min(800,params.agit_rpm+delta));
    set(rpmText,'String',sprintf('Agitation: %d RPM',params.agit_rpm));

    if params.agit_rpm > 500
        params.T_set = 38;
        set(statusMsg,'String','⚠ Temp Overshoot! RPM too high','ForegroundColor',[0.8 0 0]);
    elseif params.agit_rpm < 300
        params.T_set = 36;
        set(statusMsg,'String','⚠ Temp Drops! RPM too low','ForegroundColor',[0.2 0.2 1]);
    else
        params.T_set = 37;
        set(statusMsg,'String','Status: Normal','ForegroundColor',[0.1 0.5 0.1]);
    end

    assignin('base','params',params);
end

function perturbMenu(~,~)
    choice = menu('Choose Disturbance Event:',...
        'Decrease pH','Increase pH','Decrease Temperature');

    params = evalin('base','params');

    params.ph_down = 0;
    params.ph_up = 0;
    params.temp_down = 0;

    params.ph_down_timer = 0;
    params.ph_up_timer = 0;
    params.temp_down_timer = 0;

    switch choice
        case 1, params.ph_down = 1; params.ph_down_timer = 5;
        case 2, params.ph_up = 1; params.ph_up_timer = 5;
        case 3, params.temp_down = 1; params.temp_down_timer = 5;
    end

    assignin('base','params',params);
end

function openDashboard(~,~)
    dashboardPath = fullfile(pwd, 'reactor_dashboard.html');
    if exist(dashboardPath, 'file')
        web(dashboardPath, '-browser');
    else
        msgbox('Start simulation first to generate dashboard!', 'Info');
    end
end

function startSimulation(~,~)
    global RUNNING;
    RUNNING = true;
    runReactor();
end

function stopSimulation(~,~)
    global RUNNING;
    RUNNING = false;
end

%% --- EXPORT TO HTML WITH LIVE VALUES ---
function exportToHTML(time_data, T_data, pH_data, X_data, P_data, current_T, current_pH, health, pred_health, rpm, status)
    
    % Convert arrays to JavaScript (remove trailing commas)
    if length(time_data) > 1
        time_js = sprintf('%.2f,', time_data);
        time_js = time_js(1:end-1); % Remove last comma
        
        T_js = sprintf('%.2f,', T_data);
        T_js = T_js(1:end-1);
        
        pH_js = sprintf('%.3f,', pH_data);
        pH_js = pH_js(1:end-1);
        
        X_js = sprintf('%.3f,', X_data);
        X_js = X_js(1:end-1);
        
        P_js = sprintf('%.3f,', P_data);
        P_js = P_js(1:end-1);
    else
        time_js = sprintf('%.2f', time_data);
        T_js = sprintf('%.2f', T_data);
        pH_js = sprintf('%.3f', pH_data);
        X_js = sprintf('%.3f', X_data);
        P_js = sprintf('%.3f', P_data);
    end
    
    % Health colors
    if health >= 80
        health_color = '#10b981';
    elseif health >= 50
        health_color = '#f59e0b';
    else
        health_color = '#ef4444';
    end
    
    if pred_health >= 80
        pred_color = '#10b981';
    elseif pred_health >= 50
        pred_color = '#f59e0b';
    else
        pred_color = '#ef4444';
    end
    
    % Clean status text - remove unicode triangles that might not display
    status_clean = strrep(status, '⚠', 'WARNING:');
    if isempty(status_clean)
        status_clean = 'Normal';
    end
    
    % Create HTML with current live values
    html_content = sprintf(['<!DOCTYPE html>\n' ...
'<html><head><meta charset="UTF-8">\n' ...
'<meta http-equiv="refresh" content="2">\n' ...
'<meta http-equiv="cache-control" content="no-cache, must-revalidate">\n' ...
'<meta http-equiv="expires" content="0">\n' ...
'<meta http-equiv="pragma" content="no-cache">\n' ...
'<title>Insulin Reactor IoT</title>\n' ...
'<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>\n' ...
'<style>\n' ...
'*{margin:0;padding:0;box-sizing:border-box}\n' ...
'body{font-family:Arial,sans-serif;background:linear-gradient(135deg,#667eea 0%%,#764ba2 100%%);min-height:100vh;padding:20px}\n' ...
'.container{max-width:1400px;margin:0 auto}\n' ...
'.header{text-align:center;color:white;margin-bottom:25px}\n' ...
'.header h1{font-size:2.5em;text-shadow:2px 2px 4px rgba(0,0,0,0.4);margin-bottom:5px}\n' ...
'.live{display:inline-block;width:12px;height:12px;background:#10b981;border-radius:50%%;animation:pulse 1.5s infinite;margin-right:8px}\n' ...
'@keyframes pulse{0%%,100%%{opacity:1;transform:scale(1)}50%%{opacity:0.3;transform:scale(0.9)}}\n' ...
'.status-bar{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:15px;margin-bottom:25px}\n' ...
'.card{background:white;border-radius:15px;padding:20px;box-shadow:0 8px 16px rgba(0,0,0,0.2);transition:transform 0.3s}\n' ...
'.card:hover{transform:translateY(-4px)}\n' ...
'.card h3{font-size:0.85em;color:#666;margin-bottom:8px;text-transform:uppercase;font-weight:600;letter-spacing:0.5px}\n' ...
'.card .value{font-size:2em;font-weight:bold;color:#333;transition:all 0.3s}\n' ...
'.charts{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;margin-bottom:20px}\n' ...
'.chart-box{background:white;border-radius:15px;padding:20px;box-shadow:0 8px 16px rgba(0,0,0,0.2)}\n' ...
'.chart-box h2{margin:0 0 15px;color:#333;font-size:1.1em;font-weight:600}\n' ...
'canvas{max-height:240px !important}\n' ...
'.footer{text-align:center;color:white;margin-top:15px;font-size:0.9em;font-weight:500}\n' ...
'</style></head><body>\n' ...
'<div class="container">\n' ...
'<div class="header">\n' ...
'<h1>🧬 INSULIN REACTOR IoT DASHBOARD</h1>\n' ...
'<p><span class="live"></span>LIVE - Real-Time Monitoring</p>\n' ...
'</div>\n' ...
'<div class="status-bar">\n' ...
'<div class="card"><h3>Current Health</h3><div class="value" style="color:%s">%d%%</div></div>\n' ...
'<div class="card"><h3>AI Predicted (1h)</h3><div class="value" style="color:%s">%d%%</div></div>\n' ...
'<div class="card"><h3>Temperature</h3><div class="value">%.2f°C</div></div>\n' ...
'<div class="card"><h3>pH Level</h3><div class="value">%.3f</div></div>\n' ...
'<div class="card"><h3>RPM</h3><div class="value">%d</div></div>\n' ...
'<div class="card"><h3>Status</h3><div class="value" style="font-size:1.1em">%s</div></div>\n' ...
'</div>\n' ...
'<div class="charts">\n' ...
'<div class="chart-box"><h2>🌡️ Temperature (°C)</h2><canvas id="c1"></canvas></div>\n' ...
'<div class="chart-box"><h2>⚗️ pH Level</h2><canvas id="c2"></canvas></div>\n' ...
'<div class="chart-box"><h2>🧫 Biomass (g/L)</h2><canvas id="c3"></canvas></div>\n' ...
'<div class="chart-box"><h2>💉 Insulin Production (g/L)</h2><canvas id="c4"></canvas></div>\n' ...
'</div>\n' ...
'<div class="footer">⚡ Last Update: %s | Next refresh in 2 seconds</div>\n' ...
'</div>\n' ...
'<script>\n' ...
'const cfg={type:"line",options:{responsive:true,maintainAspectRatio:false,animation:{duration:0},scales:{x:{display:true,ticks:{maxTicksLimit:10}},y:{display:true}},plugins:{legend:{display:false}},interaction:{intersect:false,mode:"index"}}};\n' ...
'new Chart(document.getElementById("c1"),{...cfg,data:{labels:[%s],datasets:[{data:[%s],borderColor:"rgb(239,68,68)",backgroundColor:"rgba(239,68,68,0.1)",borderWidth:2.5,tension:0.4,pointRadius:0}]}});\n' ...
'new Chart(document.getElementById("c2"),{...cfg,data:{labels:[%s],datasets:[{data:[%s],borderColor:"rgb(59,130,246)",backgroundColor:"rgba(59,130,246,0.1)",borderWidth:2.5,tension:0.4,pointRadius:0}]}});\n' ...
'new Chart(document.getElementById("c3"),{...cfg,data:{labels:[%s],datasets:[{data:[%s],borderColor:"rgb(34,197,94)",backgroundColor:"rgba(34,197,94,0.1)",borderWidth:2.5,tension:0.4,pointRadius:0}]}});\n' ...
'new Chart(document.getElementById("c4"),{...cfg,data:{labels:[%s],datasets:[{data:[%s],borderColor:"rgb(168,85,247)",backgroundColor:"rgba(168,85,247,0.1)",borderWidth:2.5,tension:0.4,pointRadius:0}]}});\n' ...
'</script></body></html>'], ...
        health_color, round(health), pred_color, round(pred_health), ...
        current_T, current_pH, rpm, status_clean, datestr(now, 'HH:MM:SS'), ...
        time_js, T_js, time_js, pH_js, time_js, X_js, time_js, P_js);
    
    % Write to file
    fid = fopen('reactor_dashboard.html', 'w');
    if fid ~= -1
        fprintf(fid, '%s', html_content);
        fclose(fid);
    end
end

%% --- AI PREDICTION ---
function predicted_health = predictHealthPrecise(T, pH, X, P, rpm, params, T_history, pH_history, health_history)
    prediction_steps = 10;
    dt = 0.1;
    
    T_pred = T;
    pH_pred = pH;
    X_pred = X;
    P_pred = P;
    
    if length(T_history) >= 3
        T_trend = mean(diff(T_history(end-2:end)));
        pH_trend = mean(diff(pH_history(end-2:end)));
    else
        T_trend = 0;
        pH_trend = 0;
    end
    
    for step = 1:prediction_steps
        pH_pert_effect = 0;
        T_pert_effect = 0;
        
        if params.ph_down && params.ph_down_timer > 0
            remaining_pert = max(0, params.ph_down_timer - step);
            pH_pert_effect = -0.01 * remaining_pert;
        end
        
        if params.ph_up && params.ph_up_timer > 0
            remaining_pert = max(0, params.ph_up_timer - step);
            pH_pert_effect = 0.01 * remaining_pert;
        end
        
        if params.temp_down && params.temp_down_timer > 0
            remaining_pert = max(0, params.temp_down_timer - step);
            T_pert_effect = -0.05 * remaining_pert;
        end
        
        fT = exp(-((T_pred - params.T_opt)^2)/10);
        fPH = exp(-((pH_pred - params.pH_opt)^2)/1.5);
        
        mu = params.mu_opt * fT * fPH * (1 - X_pred/params.Xmax);
        
        dX = mu * X_pred;
        dP = params.alpha * mu * X_pred + params.beta * X_pred;
        
        X_pred = max(0, X_pred + dX*dt);
        P_pred = max(0, P_pred + dP*dt);
        
        agit_factor = 1 + 0.003*(rpm - 300)/300;
        
        if rpm > 500
            T_set_pred = 38;
        elseif rpm < 300
            T_set_pred = 36;
        else
            T_set_pred = 37;
        end
        
        dT = params.k_heat*mu*X_pred*agit_factor - params.k_cool*(T_pred - T_set_pred);
        T_pred = T_pred + (dT + T_trend*0.3)*dt + T_pert_effect;
        T_pred = min(max(T_pred, 20), 45);
        
        dPH = -params.k_acid*mu*X_pred + params.k_base*(params.pH_opt - pH_pred);
        pH_pred = pH_pred + (dPH + pH_trend*0.2)*dt + pH_pert_effect;
        pH_pred = min(max(pH_pred, 5), 9);
    end
    
    scoreT = max(0, 1 - abs(T_pred - 37)/5);
    scorePH = max(0, 1 - abs(pH_pred - 7)/0.7);
    scoreX = min(X_pred/5, 1);
    scoreP = min(P_pred/1.5, 1);
    
    base_health = 100*(0.3*scoreT + 0.3*scorePH + 0.2*scoreX + 0.2*scoreP);
    
    penalty = 0;
    
    if rpm < 250
        rpm_penalty = (250 - rpm) * 0.8;
    elseif rpm < 300
        rpm_penalty = (300 - rpm) * 0.4;
    elseif rpm > 550
        rpm_penalty = (rpm - 550) * 0.9;
    elseif rpm > 500
        rpm_penalty = (rpm - 500) * 0.5;
    else
        rpm_penalty = 0;
    end
    penalty = penalty + rpm_penalty;
    
    pH_deviation = abs(pH_pred - 7.0);
    if pH_deviation > 0.2
        pH_penalty = 30 * (exp(pH_deviation * 1.5) - 1);
        penalty = penalty + pH_penalty;
    end
    
    T_deviation = abs(T_pred - 37);
    if T_deviation > 1.0
        T_penalty = 15 * (exp(T_deviation * 0.4) - 1);
        penalty = penalty + T_penalty;
    end
    
    if params.ph_down || params.ph_up
        penalty = penalty + 8 * max([params.ph_down_timer, params.ph_up_timer]);
    end
    if params.temp_down
        penalty = penalty + 12 * params.temp_down_timer;
    end
    
    if length(health_history) >= 5
        recent_health = health_history(~isnan(health_history));
        if length(recent_health) >= 3
            health_trend = mean(diff(recent_health(end-2:end)));
            trend_impact = health_trend * 5;
            base_health = base_health + trend_impact;
        end
    end
    
    predicted_health = max(0, min(100, base_health - penalty));
end

%% --- MAIN SIMULATION ---
function runReactor()
    global RUNNING;

    ax1 = evalin('base','ax1');
    ax2 = evalin('base','ax2');
    ax3 = evalin('base','ax3');
    ax4 = evalin('base','ax4');

    healthText = evalin('base','healthText');
    predText = evalin('base','predText');
    statusMsg = evalin('base','statusMsg');

    params = evalin('base','params');

    X = 0.1; P = 0; T = 37; pH = 7;
    dt = 0.1; t = 0;

    % Data storage
    time_data = [];
    T_data = [];
    pH_data = [];
    X_data = [];
    P_data = [];

    history_length = 30;
    health_history = NaN(1, history_length);
    T_history = NaN(1, history_length);
    pH_history = NaN(1, history_length);
    
    step_counter = 0;
    predicted_health_value = 100;
    
    % Auto-open dashboard after 1 second
    pause(1);
    openDashboard();

    while RUNNING && ishandle(ax1)

        step_counter = step_counter + 1;
        params = evalin('base','params');

        %% --- Perturbations ---
        if params.ph_down && params.ph_down_timer > 0
            pH = pH - 0.01;
            params.ph_down_timer = params.ph_down_timer - 1;
        else
            params.ph_down = 0;
        end

        if params.ph_up && params.ph_up_timer > 0
            pH = pH + 0.01;
            params.ph_up_timer = params.ph_up_timer - 1;
        else
            params.ph_up = 0;
        end

        if params.temp_down && params.temp_down_timer > 0
            T = T - 0.05;
            params.temp_down_timer = params.temp_down_timer - 1;
        else
            params.temp_down = 0;
        end

        assignin('base','params',params);

        %% --- Dynamics ---
        fT = exp(-((T - params.T_opt)^2)/10);
        fPH = exp(-((pH - params.pH_opt)^2)/1.5);

        mu = params.mu_opt * fT * fPH * (1 - X/params.Xmax) * (1 + params.mu_var_scale*randn);

        dX = mu * X;
        dP = params.alpha * mu * X + params.beta * X;

        agit_factor = 1 + 0.003*(params.agit_rpm - 300)/300;

        dT = params.k_heat*mu*X*agit_factor - params.k_cool*(T - params.T_set) + params.T_noise_scale*randn;
        dPH = -params.k_acid*mu*X + params.k_base*(params.pH_opt - pH) + params.pH_noise_scale*randn;

        X = max(0, X + dX*dt);
        P = max(0, P + dP*dt);
        T = min(max(T + dT*dt, 20), 45);
        pH = min(max(pH + dPH*dt, 5), 9);

        t = t + dt;

        % Store data
        time_data = [time_data t];
        T_data = [T_data T];
        pH_data = [pH_data pH];
        X_data = [X_data X];
        P_data = [P_data P];
        
        % Keep last 100 points
        if length(time_data) > 100
            time_data = time_data(end-99:end);
            T_data = T_data(end-99:end);
            pH_data = pH_data(end-99:end);
            X_data = X_data(end-99:end);
            P_data = P_data(end-99:end);
        end

        %% --- Health ---
        scoreT = max(0, 1 - abs(T - 37)/5);
        scorePH = max(0, 1 - abs(pH - 7)/0.7);
        scoreX = min(X/5, 1);
        scoreP = min(P/1.5, 1);

        health = 100*(0.3*scoreT + 0.3*scorePH + 0.2*scoreX + 0.2*scoreP);

        rpm_ok = params.agit_rpm >= 300 && params.agit_rpm <= 500;
        ph_ok = pH >= 6.8 && pH <= 7.2;
        t_ok = T >= 36 && T <= 38;

        alertText = "";
        penalty = 0;

        if ~rpm_ok
            dev_rpm = max(0, abs(params.agit_rpm - 400) - 100);
            penalty = penalty + dev_rpm * 0.5;
            alertText = [alertText '⚠ RPM '];
        end

        if ~ph_ok
            dev_ph = max(0, abs(pH - 7) - 0.2);
            penalty = penalty + dev_ph * 50;
            alertText = [alertText '⚠ pH '];
        end

        if ~t_ok
            dev_T = max(0, abs(T - 37) - 1);
            penalty = penalty + dev_T * 10;
            alertText = [alertText '⚠ Temp '];
        end

        health = max(0, health - penalty);

        if ~isempty(alertText)
            set(statusMsg,'String',alertText,'ForegroundColor',[0.8 0 0]);
        else
            set(statusMsg,'String','Status: Normal','ForegroundColor',[0.1 0.5 0.1]);
        end

        if health > 80
            col = [0 0.5 0];
        elseif health > 50
            col = [0.8 0.5 0];
        else
            col = [0.8 0 0];
        end

        set(healthText,'String',sprintf('Batch Health: %3.0f %%', health),'ForegroundColor',col);

        %% --- Update History ---
        health_history = [health_history(2:end) health];
        T_history = [T_history(2:end) T];
        pH_history = [pH_history(2:end) pH];

        %% --- AI PREDICTION ---
        if step_counter > 10 && mod(step_counter, 5) == 0
            
            predicted_health_value = predictHealthPrecise(T, pH, X, P, params.agit_rpm, ...
                params, T_history, pH_history, health_history);

            str = sprintf('AI Predicted Health (1h): %d %%', round(predicted_health_value));

            if predicted_health_value < 50
                col_pred = [0.9 0.1 0.1];
            elseif predicted_health_value < 70
                col_pred = [0.9 0.5 0.0];
            elseif predicted_health_value < 85
                col_pred = [0.7 0.7 0.0];
            else
                col_pred = [0 0.6 0];
            end

            set(predText, 'String', str, 'ForegroundColor', col_pred);
        end

        if mod(step_counter, 20) == 0
            status_text = get(statusMsg, 'String');
            exportToHTML(time_data, T_data, pH_data, X_data, P_data, T, pH, ...
                health, predicted_health_value, params.agit_rpm, status_text);
        end

        plot(ax1, t, T, 'r.', 'MarkerSize', 8);
        plot(ax2, t, pH, 'b.', 'MarkerSize', 8);
        plot(ax3, t, X, 'g.', 'MarkerSize', 8);
        plot(ax4, t, P, 'm.', 'MarkerSize', 8);

        drawnow;
        pause(0.05);
    end
end