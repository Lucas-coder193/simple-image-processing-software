%% processImage函数
function processImage(fig, processFunc)
    % 获取应用数据
    appData = guidata(fig);
    if isempty(appData.original)
        errordlg('请先加载图像!', '错误'); 
        return;
    end
    
    % 获取滚动面板和坐标轴
    scrollPanel1 = findobj(fig, 'Tag', 'OriginalScrollPanel');
    scrollPanel2 = findobj(fig, 'Tag', 'ProcessedScrollPanel');
    ax1 = findobj(scrollPanel1, 'Type', 'Axes');
    ax2 = findobj(scrollPanel2, 'Type', 'Axes');
    
    try
        % 执行处理
        if strcmp(func2str(processFunc), 'scaleImageCustom')
            %% ==== 缩放操作处理 ====
            % 缩放操作特殊处理
            [processedImg, scale] = scaleImageCustom(appData.original);
            
            % 计算处理后图像的实际尺寸
            hProc = size(processedImg, 1);
            wProc = size(processedImg, 2);
            
            % === 核心修复：设置坐标轴精确尺寸 ===
            set(ax2, 'Units', 'pixels',...  
                     'Position', [1 1 wProc hProc],... % 坐标轴匹配图像尺寸
                     'XLim', [0.5 wProc+0.5],...
                     'YLim', [0.5 hProc+0.5],...
                     'DataAspectRatio', [1 1 1]);
            
            % 显示缩放后的实际像素图像
            imshow(processedImg, 'Parent', ax2);
            
        else
            %% ==== 其他操作处理 ====
            % 执行非缩放操作
            processedImg = processFunc(appData.original);
            
            % 获取当前显示尺寸
            displaySize = appData.displaySize;
            
            % 将处理后的图像缩放到显示尺寸
            dispImg = imresize(processedImg, displaySize(1:2));
            
            % 显示统一尺寸的图像
            imshow(dispImg, 'Parent', ax2);
            
            % 设置坐标轴精确匹配显示尺寸
            set(ax2, 'Units', 'pixels',...
                     'Position', [1 1 displaySize(2) displaySize(1)],...
                     'XLim', [0.5 displaySize(2)+0.5],...
                     'YLim', [0.5 displaySize(1)+0.5],...
                     'DataAspectRatio', [1 1 1]);
        end
        
        %% ==== 原图显示（保持不变） ====
        % 显示原始图像（使用统一显示尺寸）
        imshow(imresize(appData.original, appData.displaySize(1:2)), 'Parent', ax1);
        set(ax1, 'Units', 'pixels',...
                 'Position', [1 1 appData.displaySize(2) appData.displaySize(1)],...
                 'XLim', [0.5 appData.displaySize(2)+0.5],...
                 'YLim', [0.5 appData.displaySize(1)+0.5],...
                 'DataAspectRatio', [1 1 1]); % 保持宽高比
        
        %% ==== 更新滚动面板内容区域 ====
        % 原图面板
        scrollPanel1.AutoResizeChildren = 'off';
        set(ax1, 'Units', 'pixels', 'Position', [1 1 appData.displaySize(2) appData.displaySize(1)]);
        
        % 处理结果面板
        scrollPanel2.AutoResizeChildren = 'off';
        
        if strcmp(func2str(processFunc), 'scaleImageCustom')
            % 缩放操作使用实际像素尺寸
            set(ax2, 'Units', 'pixels', 'Position', [1 1 size(processedImg, 2) size(processedImg, 1)]);
        else
            % 其他操作使用统一显示尺寸
            set(ax2, 'Units', 'pixels', 'Position', [1 1 appData.displaySize(2) appData.displaySize(1)]);
        end
        
        %% ==== 更新数据存储 ====
        appData.processed = processedImg;
        guidata(fig, appData);
        
        % 添加调试信息（可选）
        disp(['原图尺寸: ', num2str(size(appData.original))]);
        disp(['处理后尺寸: ', num2str(size(processedImg))]);
        if strcmp(func2str(processFunc), 'scaleImageCustom')
            disp(['显示尺寸: ', num2str([size(processedImg, 2), size(processedImg, 1)])]);
        else
            disp(['显示尺寸: ', num2str(appData.displaySize(1:2))]);
        end
        
    catch ME
        errordlg(sprintf('处理失败: %s', ME.message), '错误');
    end
end