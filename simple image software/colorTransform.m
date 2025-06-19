%% 颜色变换 colorTransform.m 
function output = colorTransform(input)
    % 扩展的颜色空间转换选项
    options = {
        'RGB转HSV',  'HSV转RGB',...
        'RGB转CMY',  'CMY转RGB',...
        'RGB转HSI',  'HSI转RGB',...
        '调整饱和度'
    };
    
    [sel, ok] = listdlg('ListString', options, 'SelectionMode','single',...
                       'Name','颜色变换', 'PromptString','选择操作:',...
                       'ListSize', [200 150]);
    
    if ~ok
        output = input;
        return;
    end
    
    switch options{sel}
        case 'RGB转HSV'
            output = rgb2hsv_custom(input);
        case 'HSV转RGB'
            output = hsv2rgb_custom(input);
        case 'RGB转CMY'
            output = rgb2cmy(input);
        case 'CMY转RGB'
            output = cmy2rgb(input);
        case 'RGB转HSI'
            output = rgb2hsi(input);
        case 'HSI转RGB'
            output = hsi2rgb(input);
        case '调整饱和度'
            output = adjustSaturation(input);
    end
end

%% 颜色空间转换函数
function hsv = rgb2hsv_custom(rgb)
    % 手动实现RGB转HSV
    r = rgb(:,:,1); g = rgb(:,:,2); b = rgb(:,:,3);
    
    maxVal = max(rgb,[],3);
    minVal = min(rgb,[],3);
    delta = maxVal - minVal;
    
    h = zeros(size(r));
    s = delta ./ (maxVal + eps);
    v = maxVal;
    
    % 计算色相
    idx = delta ~= 0;
    r_idx = (maxVal == r) & idx;
    g_idx = (maxVal == g) & idx;
    b_idx = (maxVal == b) & idx;
    
    h(r_idx) = mod((g(r_idx) - b(r_idx))./delta(r_idx), 6)/6;
    h(g_idx) = (2 + (b(g_idx) - r(g_idx))./delta(g_idx))/6;
    h(b_idx) = (4 + (r(b_idx) - g(b_idx))./delta(b_idx))/6;
    
    hsv = cat(3, h, s, v);
end

function rgb = hsv2rgb_custom(hsv)
    % 手动实现HSV转RGB
    h = hsv(:,:,1)*6; s = hsv(:,:,2); v = hsv(:,:,3);
    
    i = floor(h);
    f = h - i;
    p = v.*(1 - s);
    q = v.*(1 - f.*s);
    t = v.*(1 - (1 - f).*s);
    
    rgb = zeros(size(hsv));
    
    i = mod(i,6);
    for ch = 1:3
        c = zeros(size(h));
        c(i==0) = v(i==0);
        c(i==1) = q(i==1);
        c(i==2) = p(i==2);
        c(i==3) = p(i==3);
        c(i==4) = t(i==4);
        c(i==5) = v(i==5);
        
        c(i==1 & ch==2) = v(i==1 & ch==2);
        c(i==2 & ch==1) = t(i==2 & ch==1);
        % ...其他通道类似处理
        
        rgb(:,:,ch) = c;
    end
end

%% 新增CMY转换函数
function cmy = rgb2cmy(rgb)
    % RGB转CMY (补色空间)
    % 输入: [0,1]范围的RGB图像
    % 输出: [0,1]范围的CMY图像
    cmy = 1 - rgb;
    cmy = max(min(cmy, 1), 0); % 确保在[0,1]范围内
end

function rgb = cmy2rgb(cmy)
    % CMY转RGB
    % 输入: [0,1]范围的CMY图像
    % 输出: [0,1]范围的RGB图像
    rgb = 1 - cmy;
    rgb = max(min(rgb, 1), 0); % 确保在[0,1]范围内
end

%% 新增HSI转换函数
function hsi = rgb2hsi(rgb)
    % 输入验证
    validateattributes(rgb, {'double'}, {'size',[NaN,NaN,3], '>=',0, '<=',1});
    
    % 分离通道
    r = rgb(:,:,1); g = rgb(:,:,2); b = rgb(:,:,3);
    
    % 计算亮度I
    I = (r + g + b) / 3;
    
    % 计算饱和度S（带防除零保护）
    minRGB = min(rgb, [], 3);
    S = 1 - minRGB ./ (I + eps);
    S(I < 0.01) = 0; % 处理极暗区域
    
    % 计算色相H（完全防崩溃实现）
    numerator = 0.5 * ((r - g) + (r - b));
    denominator = sqrt((r - g).^2 + (r - b).*(g - b)) + eps;
    theta = acos(min(max(numerator ./ denominator, -1), 1)); % 限制在[-1,1]范围内
    
    H = theta;
    H(b > g) = 2*pi - H(b > g);
    H = H / (2*pi); % 归一化到[0,1]
    
    hsi = cat(3, H, S, I);
end

function rgb = hsi2rgb(hsi)
    % 输入验证
    assert(ndims(hsi) == 3 && size(hsi,3) == 3, '输入必须是3通道HSI图像');
    
    % 获取尺寸并预分配输出
    [rows, cols, ~] = size(hsi);
    rgb = zeros(rows, cols, 3);
    
    % 逐个像素处理（避免维度问题）
    for i = 1:rows
        for j = 1:cols
            H = hsi(i,j,1) * 2 * pi;
            S = hsi(i,j,2);
            I = hsi(i,j,3);
            
            % 分区间计算
            if (0 <= H) && (H < 2*pi/3)
                R = I * (1 + S * cos(H) / (cos(pi/3 - H) + eps));
                B = I * (1 - S);
                G = 3*I - (R + B);
            elseif (2*pi/3 <= H) && (H < 4*pi/3)
                H = H - 2*pi/3;
                R = I * (1 - S);
                G = I * (1 + S * cos(H) / (cos(pi/3 - H) + eps));
                B = 3*I - (R + G);
            else
                H = H - 4*pi/3;
                G = I * (1 - S);
                B = I * (1 + S * cos(H) / (cos(pi/3 - H) + eps));
                R = 3*I - (G + B);
            end
            
            rgb(i,j,:) = [R, G, B];
        end
    end
    
    % 数值裁剪
    rgb = max(min(rgb, 1), 0);
end
%% 调整饱和度函数 (改进版)
function output = adjustSaturation(input)
    answer = inputdlg({'饱和度系数 (0-2):', '色彩空间 (HSV/HSI):'}, ...
                     '饱和度调整', [1 30; 1 30], {'1.5', 'HSV'});
    
    if isempty(answer)
        output = input;
        return;
    end
    
    factor = str2double(answer{1});
    space = answer{2};
    
    if isnan(factor) || factor < 0
        errordlg('无效的系数');
        output = input;
        return;
    end
    
    switch upper(space)
        case 'HSV'
            hsv = rgb2hsv_custom(input);
            hsv(:,:,2) = min(hsv(:,:,2) * factor, 1);
            output = hsv2rgb_custom(hsv);
        case 'HSI'
            hsi = rgb2hsi(input);
            hsi(:,:,2) = min(hsi(:,:,2) * factor, 1);
            output = hsi2rgb(hsi);
        otherwise
            errordlg('不支持的色彩空间');
            output = input;
    end
end