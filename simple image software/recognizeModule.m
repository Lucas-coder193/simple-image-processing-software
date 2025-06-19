%% 对象识别模块 - recognizeModule.m
function output = recognizeModule(input)
    % 输入验证
    validateattributes(input, {'double'}, {'>=',0, '<=',1, 'nonempty'});
    
    % 颜色识别和形状检测选项
    options = {'红色物体识别', '圆形检测'};
    [sel, ok] = listdlg('ListString', options, 'SelectionMode','single',...
        'Name','识别类型', 'PromptString','选择识别模式:');
    
    if ~ok || isempty(sel)
        output = input;
        return;
    end
    
    % 执行对应操作
    switch options{sel}
        case '红色物体识别'
            output = detectRedObjects(input);
        case '圆形检测'
            output = detectCircles(input);
        otherwise
            error('未知的识别模式');
    end
end

%% 红色物体检测
function output = detectRedObjects(rgbImg)
    % 转换到HSV空间
    hsv = rgb2hsv_custom(rgbImg);
    hue = hsv(:,:,1);
    sat = hsv(:,:,2);
    
    % 红色范围检测（色相0-0.1和0.9-1.0）
    mask = (hue < 0.1 | hue > 0.9) & (sat > 0.5);
    
    % 标记红色区域为白色
    output = rgbImg;
    output(repmat(mask,[1 1 3])) = 1;
end

%% 自定义RGB转HSV
function hsv = rgb2hsv_custom(rgb)
    % 输入验证
    validateattributes(rgb, {'double'}, {'size',[NaN,NaN,3], '>=',0, '<=',1});
    
    r = rgb(:,:,1); 
    g = rgb(:,:,2); 
    b = rgb(:,:,3);
    
    % 计算各通道极值
    maxVal = max(rgb,[],3);
    minVal = min(rgb,[],3);
    delta = maxVal - minVal;
    
    % 初始化HSV分量
    h = zeros(size(r));
    s = delta ./ (maxVal + eps);
    v = maxVal;
    
    % 计算色相分量
    validDelta = delta ~= 0;
    
    % 红色主导区域
    redMask = (maxVal == r) & validDelta;
    h(redMask) = mod((g(redMask) - b(redMask))./delta(redMask), 6)/6;
    
    % 绿色主导区域
    greenMask = (maxVal == g) & validDelta;
    h(greenMask) = (2 + (b(greenMask) - r(greenMask))./delta(greenMask))/6;
    
    % 蓝色主导区域
    blueMask = (maxVal == b) & validDelta;
    h(blueMask) = (4 + (r(blueMask) - g(blueMask))./delta(blueMask))/6;
    
    hsv = cat(3, h, s, v);
end

%% 圆形检测功能
function output = detectCircles(rgbImg)
    % 转换为灰度图
    gray = rgb2gray_custom(rgbImg);
    
    % 边缘检测（自主实现Prewitt算子）
    edges = prewittEdge(gray);
    
    % 霍夫圆变换参数
    minRadius = 15;
    maxRadius = 30;
    [centers] = houghCircles(edges, [minRadius, maxRadius]);
    
    % 在原图标记结果
    output = insertCircles(rgbImg, centers);
end

%% 自定义Prewitt边缘检测
function edgeImg = prewittEdge(grayImg)
    % 定义Prewitt算子
    horizontal = [-1 0 1; -1 0 1; -1 0 1];
    vertical = [1 1 1; 0 0 0; -1 -1 -1];
    
    % 卷积运算
    Gx = conv2(grayImg, horizontal, 'same');
    Gy = conv2(grayImg, vertical, 'same');
    
    % 计算梯度幅值
    edgeImg = sqrt(Gx.^2 + Gy.^2) > 0.3; % 阈值设为0.3
end

%% 霍夫圆变换核心算法
function [centers] = houghCircles(edgeImg, radiusRange)
    % 参数初始化
    [h, w] = size(edgeImg);
    accumulator = zeros(h, w, radiusRange(2)-radiusRange(1)+1);
    
    % 获取边缘点坐标
    [y, x] = find(edgeImg);
    
    % 遍历所有边缘点
    for k = 1:length(x)
        % 遍历所有可能半径
        for rIdx = 1:(radiusRange(2)-radiusRange(1)+1)
            r = radiusRange(1) + rIdx - 1;
            
            % 生成圆周参数空间
            theta = 0:pi/18:2*pi; % 20度间隔
            a = round(x(k) - r*cos(theta));
            b = round(y(k) - r*sin(theta));
            
            % 验证坐标有效性
            valid = (a > 0 & a <= w) & (b > 0 & b <= h);
            a = a(valid);
            b = b(valid);
            
            % 更新累加器
            for n = 1:length(a)
                accumulator(b(n), a(n), rIdx) = accumulator(b(n), a(n), rIdx) + 1;
            end
        end
    end
    
    % 寻找候选圆心
    centers = [];
    threshold = max(accumulator(:)) * 0.8; % 使用80%最大值为阈值
    [b, a, rIdx] = ind2sub(size(accumulator), find(accumulator > threshold));
    if ~isempty(b)
        r = radiusRange(1) + rIdx - 1;
        centers = [a, b, r];
    end
end

%% 绘制检测结果
function img = insertCircles(img, centers)
    % 输入验证
    validateattributes(centers, {'numeric'}, {'ncols',3, 'positive'});
    
    % 为每个圆心绘制标记
    for i = 1:size(centers,1)
        img = drawCircle(img, centers(i,1), centers(i,2), centers(i,3));
    end
end

function img = drawCircle(img, x0, y0, r)
    % 生成圆形坐标
    theta = 0:0.1:2*pi;
    x = round(x0 + r*cos(theta));
    y = round(y0 + r*sin(theta));
    
    % 去除越界点
    valid = (x > 0 & x <= size(img,2)) & (y > 0 & y <= size(img,1));
    x = x(valid);
    y = y(valid);
    
    % 绘制白色边界（RGB通道）
    for ch = 1:3
        for k = 1:length(x)
            img(y(k), x(k), ch) = 1; % 白色
        end
    end
end

%% 灰度转换模块（与系统其他模块保持一致）
function gray = rgb2gray_custom(rgb)
    coefficients = [0.2989, 0.5870, 0.1140]; % BT.601标准
    gray = sum(bsxfun(@times, rgb, reshape(coefficients,1,1,[])), 3);
    gray = min(max(gray, 0), 1);
end