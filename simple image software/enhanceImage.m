%% 新增模块2：图像增强 enhanceImage.m
function output = enhanceImage(input)
    % 记录原始尺寸和数据类型
    originalSize = size(input);
    inputClass = class(input);
    
    % 创建参数输入对话框
    prompt = {
        '对比度强度 (0.1-5):', 
        '噪声抑制强度 (0-1):', 
        '清晰度强度 (0-2):', 
        '亮度调整 (-1到1):'
    };
    defaults = {'1.2', '0.3', '0.8', '0'};
    answer = inputdlg(prompt, '增强参数设置', [1 30], defaults);
    
    if isempty(answer)
        output = input;
        return;
    end
    
    % 解析参数
    contrast = str2double(answer{1});
    denoise = str2double(answer{2});
    sharpness = str2double(answer{3});
    brightness = str2double(answer{4});
    
    % 参数验证
    params = [contrast, denoise, sharpness, brightness];
    if any(isnan(params)) || contrast<=0 || denoise<0 || sharpness<0
        errordlg('参数无效');
        output = input;
        return;
    end

    % 转换为双精度处理
    img = im2double(input);
    
    %% 1. 噪声抑制 (自动保持尺寸)
    if denoise > 0
        img = waveletDenoise(img, denoise);
    end
    
    %% 2. 亮度调整
    if brightness ~= 0
        img = img + brightness;
        img = min(max(img, 0), 1);
    end
    
    %% 3. 对比度增强 (S曲线)
    if contrast ~= 1
        img = 1./(1 + exp(-contrast*(img - 0.5)));
    end
    
    %% 4. 清晰度增强 (非锐化掩蔽)
    if sharpness > 0
        blurred = imgaussfilt(img, 1.5);
        detail = img - blurred;
        img = img + sharpness*detail;
        img = min(max(img, 0), 1);
    end
    
    %% 强制恢复原始尺寸和类型
    output = restoreOriginalSize(img, originalSize, inputClass);
end

%% 安全的小波去噪 (子函数)
function img = waveletDenoise(img, strength)
    % 确保偶数尺寸
    [h,w,c] = size(img); 
    if mod(h,2) ~= 0
        img = img(1:end-1,:,:);
    end
    if mod(w,2) ~= 0
        img = img(:,1:end-1,:);
    end
    
    % 分通道处理
    for ch = 1:c
        [cA,cH,cV,cD] = dwt2(img(:,:,ch), 'haar');
        threshold = strength * median(abs(cD(:)))/0.6745;
        cD = wthresh(cD, 's', threshold);
        img(:,:,ch) = idwt2(cA,cH,cV,cD, 'haar');
    end
end

%% 尺寸恢复 (子函数)
function output = restoreOriginalSize(input, targetSize, targetClass)
    % 获取当前尺寸
    inputSize = size(input);
    
    % 尺寸相同只需转换类型
    if isequal(inputSize(1:2), targetSize(1:2))
        output = cast(input, targetClass);
        return;
    end
    
    % 需要调整尺寸的情况
    try
        if ndims(input) == 3
            % 彩色图像处理
            output = zeros([targetSize(1:2), size(input,3)], targetClass);
            for ch = 1:size(input,3)
                output(:,:,ch) = cast(imresize(input(:,:,ch), targetSize(1:2)), targetClass);
            end
        else
            % 灰度图像处理
            output = cast(imresize(input, targetSize(1:2)), targetClass);
        end
    catch ME
        error('尺寸恢复失败: %s', ME.message);
    end
end