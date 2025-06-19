%% 卷积运算模块：convolution.m
function output = convolution(input, type)
    % 生成对应卷积核
    kernel = getKernel(type);
    
    % 执行手动卷积
    output = manualConv(input, kernel);
    
    %% 核生成函数
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
    
    %% 手动卷积实现
    function output = manualConv(img, k)
        % 边界对称填充
        padSize = floor(size(k)/2);
        padded = padarray(img, padSize, 'symmetric');
        
        % 初始化输出
        output = zeros(size(img), 'like', img);
        
        % 多通道处理
        for ch = 1:size(img,3)
            % 滑动窗口卷积
            [h, w] = size(padded(:,:,ch));
            [kh, kw] = size(k);
            result = zeros(h-kh+1, w-kw+1);
            
            % 核翻转（标准卷积）
            k_flipped = rot90(k, 2);
            
            % 手动计算
            for i = 1:kh
                for j = 1:kw
                    result = result + k_flipped(i,j) * ...
                             padded(i:i+end-kh, j:j+end-kw, ch);
                end
            end
            
            % 裁剪有效区域
            output(:,:,ch) = result(1:size(img,1), 1:size(img,2));
        end
        
        % 结果归一化
        if strcmpi(type, 'sharpen')
            % 保持原始亮度范围
            output = img + (output - mean(output(:)));  % 细节增强但不改变平均亮度
            output = min(max(output, 0), 1);  % 限制到[0,1]范围
        else
            % 其他滤镜保持原有归一化
            output = (output - min(output(:))) / (max(output(:)) - min(output(:)) + eps);
        end
    end
end