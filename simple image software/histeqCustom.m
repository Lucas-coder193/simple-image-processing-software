%% 直方图模块: histeqCustom.m
function output = histeqCustom(input, ~)
    % 转换为灰度图像（自主实现RGB2Gray）
    if size(input,3) == 3
        grayImg = 0.2989*input(:,:,1) + 0.5870*input(:,:,2) + 0.1140*input(:,:,3);
    else
        grayImg = input;
    end
    
    % 计算精确直方图
    [histOrig, bins] = computePreciseHistogram(grayImg);
    
    % 优化后的直方图均衡化
    [output, mapping] = advancedHistEqualization(input, grayImg, histOrig);
    
    % 显示交互弹窗（不传fig参数）
    showHistogramDialog(histOrig, bins, mapping, output);
end

%% 核心优化算法
function [output, mapping] = advancedHistEqualization(input, grayImg, histOrig)
    % 参数设置
    gamma = 0.7;       % 自适应gamma值
    clipLimit = 0.02;  % 直方图裁剪阈值
    
    % 1. 直方图裁剪（防止过度增强）
    histClipped = clipHistogram(histOrig, clipLimit);
    
    % 2. 自适应CDF计算
    cdf = cumsum(histClipped);
    cdf = (cdf - min(cdf)) / (max(cdf) - min(cdf)); % 归一化
    
    % 3. 非线性映射（自适应gamma校正）
    avgIntensity = mean(grayImg(:));
    gamma = 0.5 + 0.5*(1-avgIntensity); % 暗图使用更强校正
    cdf = cdf.^gamma;
    
    % 4. 混合映射策略
    linearMap = linspace(0, 1, 256);
    mapping = round(255 * (0.3*cdf + 0.7*linearMap)); % 混合比例可调
    
    % 5. 应用映射（带抖动处理）
    quantized = min(max(round(grayImg*255)+1, 1), 256);
    processed = mapping(quantized);
    
    % 6. 自适应对比度限制
    processed = (processed - min(processed(:))) / ...
                (max(processed(:)) - min(processed(:)));
    
    % 7. 色彩处理优化（使用自主实现的HSV转换）
    if size(input,3) == 3
        hsvImg = rgb2hsv_custom(input);
        hsvImg(:,:,3) = processed;
        output = hsv2rgb_custom(hsvImg);
    else
        output = processed;
    end
end

%% 精确直方图计算（解决边界问题）
function [counts, bins] = computePreciseHistogram(img)
    bins = linspace(0, 1, 256);
    counts = zeros(1, 256);
    
    % 线性插值分配权重
    positions = img(:)*255 + 1;
    lowerIdx = floor(positions);
    upperIdx = ceil(positions);
    upperWeight = positions - lowerIdx;
    lowerWeight = 1 - upperWeight;
    
    % 向量化计算
    validLower = (lowerIdx >= 1) & (lowerIdx <= 256);
    validUpper = (upperIdx >= 1) & (upperIdx <= 256);
    
    counts = accumarray([lowerIdx(validLower); upperIdx(validUpper)], ...
                       [lowerWeight(validLower); upperWeight(validUpper)], ...
                       [256 1])';
end

%% 直方图裁剪（防止噪声放大）
function histClipped = clipHistogram(histOrig, clipLimit)
    totalPixels = sum(histOrig);
    clipThreshold = clipLimit * totalPixels / 256;
    
    excess = sum(max(0, histOrig - clipThreshold));
    histClipped = min(histOrig, clipThreshold) + excess/256;
end

%% 自主实现的RGB转HSV
function hsv = rgb2hsv_custom(rgb)
    r = rgb(:,:,1); g = rgb(:,:,2); b = rgb(:,:,3);
    [M, I] = max(rgb, [], 3);
    m = min(rgb, [], 3);
    C = M - m;
    
    % 计算色相H
    h = zeros(size(M));
    idx = (C ~= 0);
    
    % 红色通道最大值
    r_idx = (I == 1) & idx;
    h(r_idx) = mod((g(r_idx) - b(r_idx))./C(r_idx), 6);
    
    % 绿色通道最大值
    g_idx = (I == 2) & idx;
    h(g_idx) = (b(g_idx) - r(g_idx))./C(g_idx) + 2;
    
    % 蓝色通道最大值
    b_idx = (I == 3) & idx;
    h(b_idx) = (r(b_idx) - g(b_idx))./C(b_idx) + 4;
    
    H = 60 * h;
    H(H < 0) = H(H < 0) + 360;
    
    % 计算饱和度S
    S = zeros(size(M));
    S(M ~= 0) = C(M ~= 0) ./ M(M ~= 0);
    
    % 计算亮度V
    V = M;
    
    hsv = cat(3, H/360, S, V);
end

%% 自主实现的HSV转RGB
function rgb = hsv2rgb_custom(hsv)
    H = hsv(:,:,1)*360; S = hsv(:,:,2); V = hsv(:,:,3);
    C = V .* S;
    X = C .* (1 - abs(mod(H/60, 2) - 1));
    m = V - C;
    
    rgb = zeros(size(hsv));
    
    % 分段计算RGB
    idx = (H >= 0 & H < 60);
    rgb(:,:,1) = rgb(:,:,1) + idx .* C;
    rgb(:,:,2) = rgb(:,:,2) + idx .* X;
    
    idx = (H >= 60 & H < 120);
    rgb(:,:,1) = rgb(:,:,1) + idx .* X;
    rgb(:,:,2) = rgb(:,:,2) + idx .* C;
    
    idx = (H >= 120 & H < 180);
    rgb(:,:,2) = rgb(:,:,2) + idx .* C;
    rgb(:,:,3) = rgb(:,:,3) + idx .* X;
    
    idx = (H >= 180 & H < 240);
    rgb(:,:,2) = rgb(:,:,2) + idx .* X;
    rgb(:,:,3) = rgb(:,:,3) + idx .* C;
    
    idx = (H >= 240 & H < 300);
    rgb(:,:,1) = rgb(:,:,1) + idx .* X;
    rgb(:,:,3) = rgb(:,:,3) + idx .* C;
    
    idx = (H >= 300 & H < 360);
    rgb(:,:,1) = rgb(:,:,1) + idx .* C;
    rgb(:,:,3) = rgb(:,:,3) + idx .* X;
    
    % 添加m并限制范围
    rgb = rgb + m;
    rgb = max(min(rgb, 1), 0);
end

%% 改进的显示交互
function showHistogramDialog(histOrig, bins, mapping, processedImg)
    % 计算均衡化后的直方图
    histEq = zeros(1,256);
    for i = 1:256
        newVal = min(max(mapping(i)+1,1),256);
        histEq(newVal) = histEq(newVal) + histOrig(i);
    end
    
    % 创建对比图窗
    hFig = figure('Name','直方图分析','NumberTitle','off',...
                 'Position', [100 100 900 400]);
    
    % 原图直方图
    subplot(1,3,1);
    bar(bins, histOrig, 'FaceColor',[0.3 0.6 1], 'EdgeColor','none');
    title('原图直方图'); grid on; xlim([0 1]);
    
    % 均衡后直方图
    subplot(1,3,2);
    bar(bins, histEq, 'FaceColor',[1 0.5 0.2], 'EdgeColor','none');
    title('均衡后直方图'); grid on; xlim([0 1]);
    
    % 处理结果预览
    subplot(1,3,3);
    imshow(processedImg);
    title('处理结果');
    
    % 添加统计信息
    stats = {
        ['原始均值: ' sprintf('%.2f', mean(histOrig))]
        ['均衡均值: ' sprintf('%.2f', mean(histEq))]
        ['原始熵: ' sprintf('%.2f', -sum(histOrig.*log2(histOrig+eps)))]
        ['均衡熵: ' sprintf('%.2f', -sum(histEq.*log2(histEq+eps)))]
    };
    annotation(hFig, 'textbox', [0.4 0.05 0.2 0.2],...
              'String', stats, 'EdgeColor','none');
end