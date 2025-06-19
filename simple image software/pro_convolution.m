%% 优化版卷积运算模块：convolution.m
function output = convolution(input, type)
    % 生成卷积核（保持不变）
    kernel = getKernel(type);
    
    % 执行高效手动卷积
    output = optimizedConv(input, kernel);
    
    %% 核生成函数（不变）
    function kernel = getKernel(type)
        switch lower(type)
            case 'gaussian'
                kernel = [1 2 1; 2 4 2; 1 2 1]/16; % 3x3高斯核
            case 'edge'
                kernel = [-1 -1 -1; -1 8 -1; -1 -1 -1];
            case 'emboss'
                kernel = [-2 -1 0; -1 1 1; 0 1 2];
            case 'sharpen'
                kernel = [0 -0.25 0; -0.25 1.5 -0.25; 0 -0.25 0];
        end
    end
    
    %% 优化版手动卷积实现
    function output = optimizedConv(img, k)
        % 获取卷积核尺寸
        [kh, kw] = size(k);
        padSize = floor([kh, kw]/2);
        
        % 边界对称填充（单次填充所有通道）
        padded = padarray(img, padSize, 'symmetric');
        
        % 翻转卷积核
        k_flipped = rot90(k, 2);
        
        % 初始化输出（预分配内存）
        output = zeros(size(img), 'like', img);
        [h, w, chNum] = size(img);
        
        % 多通道并行处理
        for ch = 1:chNum
            % 预提取当前通道的填充图像
            paddedChannel = padded(:, :, ch);
            
            % 优化卷积计算
            chResult = vectorizedConv(paddedChannel, k_flipped, h, w, kh, kw);
            
            % 存储当前通道结果
            output(:, :, ch) = chResult;
        end
        
        % 专用锐化处理（保持不变）
        if strcmpi(type, 'sharpen')
            output = img + (output - mean(output(:)));
            output = min(max(output, 0), 1);
        else
            % 归一化处理优化
            minVal = min(output(:));
            maxVal = max(output(:));
            range = maxVal - minVal + eps;
            output = (output - minVal) / range;
        end
    end

    %% 向量化卷积核心计算
    function result = vectorizedConv(padded, kernel, h, w, kh, kw)
        % 预分配结果矩阵
        result = zeros(h, w);
        
        % 主循环向量化优化
        for i = 1:h
            % 一次性获取当前行所有窗口的初始位置
            rowStart = i;
            rowEnd = rowStart + kh - 1;
            
            for j = 1:w
                % 计算列范围
                colStart = j;
                colEnd = colStart + kw - 1;
                
                % 提取当前卷积窗口（一次性读取整个窗口）
                window = padded(rowStart:rowEnd, colStart:colEnd);
                
                % 点积计算（单次操作替代双重循环）
                result(i, j) = sum(kernel(:) .* window(:));
            end
        end
    end
end