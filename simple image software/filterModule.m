%% 滤镜模块：filterModule.m
function output = filterModule(input)
    % 创建滤镜选择对话框
    dlg = uifigure('Name', '滤镜选择', 'Position', [300 300 250 200]);
    
    % 初始化输出
    output = input;
    
    % 添加4种滤镜选项
    uibutton(dlg, 'Text','高斯模糊', 'Position',[50 150 150 30],...
        'ButtonPushedFcn', @(src,evt) applyFilter('gaussian'));
    
    uibutton(dlg, 'Text','边缘检测', 'Position',[50 110 150 30],...
        'ButtonPushedFcn', @(src,evt) applyFilter('edge'));
    
    uibutton(dlg, 'Text','浮雕效果', 'Position',[50 70 150 30],...
        'ButtonPushedFcn', @(src,evt) applyFilter('emboss'));
    
    uibutton(dlg, 'Text','锐化', 'Position',[50 30 150 30],...
        'ButtonPushedFcn', @(src,evt) applyFilter('sharpen'));
    
    % 等待用户选择
    waitfor(dlg);
    
    %% 应用选定滤镜
    function applyFilter(filterType)
        % 调用卷积模块
        output = convolution(input, filterType);
        
        % 关闭对话框
        close(dlg);
    end
end

