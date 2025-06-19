%% 图像分割模块 - segmentModule.m
function output = segmentModule(input)
    % 创建参数选择对话框
    dlg = uifigure('Name', '分割参数设置', 'Position', [300 300 300 200]);
    
    % 方法选择下拉菜单
    uilabel(dlg, 'Text', '分割方法:', 'Position', [20 160 100 20]);
    methodDropdown = uidropdown(dlg, ...
        'Position', [120 160 150 22], ...
        'Items', {'阈值分割 (大津法)', '边缘分割 (Canny)', '区域分割 (分水岭)'}, ...
        'Value', '阈值分割 (大津法)');
    
    % 参数设置
    uilabel(dlg, 'Text', '后处理强度:', 'Position', [20 120 100 20]);
    postSlider = uislider(dlg, ...
        'Position', [120 120 150 3], ...
        'Limits', [0 1], 'Value', 0.5);
    
    % 确认按钮
    uibutton(dlg, 'Text', '执行分割', 'Position', [100 50 100 30], ...
        'ButtonPushedFcn', @(src,event) confirmSegmentation(dlg, input));
    
    % 等待对话框关闭
    uiwait(dlg);
    
    % 获取输出结果
    if isvalid(dlg) && isfield(dlg.UserData, 'output')
        output = dlg.UserData.output;
        delete(dlg);
    else
        output = input; % 用户取消时返回原图
    end
end

%% 确认分割回调函数
function confirmSegmentation(dlg, input)
    % 获取参数
    method = dlg.Children(4).Value; % 方法下拉菜单
    postStrength = dlg.Children(2).Value; % 滑块值
    
    % 灰度转换
    if size(input,3) == 3
        grayImg = 0.2989*input(:,:,1) + 0.5870*input(:,:,2) + 0.1140*input(:,:,3);
    else
        grayImg = input;
    end
    
    % 执行分割
    switch method
        case '阈值分割 (大津法)'
            level = graythresh(grayImg);
            binaryImg = imbinarize(grayImg, level);
            
        case '边缘分割 (Canny)'
            edges = edge(grayImg, 'Canny', [0.1*postStrength 0.3]);
            se = strel('disk', round(3*postStrength));
            binaryImg = imclose(edges, se);
            
        case '区域分割 (分水岭)'
            hy = fspecial('sobel');
            grad = imfilter(double(grayImg), hy);
            grad = grad / max(grad(:));
            binaryImg = watershed(grad) == 0;
    end
    
    % 后处理（强度由滑块控制）
    binaryImg = bwmorph(binaryImg, 'clean');
    binaryImg = imfill(binaryImg, 'holes');
    if postStrength > 0.5
        binaryImg = bwareaopen(binaryImg, round(100*postStrength));
    end
    
    % 保存结果
    dlg.UserData.output = binaryImg;
    uiresume(dlg);
end