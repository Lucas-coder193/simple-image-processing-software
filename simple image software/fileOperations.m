%% 文件操作模块：fileOperations.m
function varargout = fileOperations(action, varargin)
    % 统一文件操作入口函数
    switch action
        case 'load'
            [varargout{1:nargout}] = loadImage(varargin{:});
        case 'save'
            [varargout{1:nargout}] = saveImage(varargin{:});
        otherwise
            error('无效操作: %s', action);
    end
end

%% 加载图像
function loadImage(fig)
    % 获取应用数据
    appData = guidata(fig);
    
    % 获取坐标轴和滚动面板
    ax1 = findobj(fig, 'Tag', 'OriginalAxes');
    ax2 = findobj(fig, 'Tag', 'ProcessedAxes');
    scrollPanel1 = findobj(fig, 'Tag', 'OriginalScrollPanel');
    scrollPanel2 = findobj(fig, 'Tag', 'ProcessedScrollPanel');
    
    [file, path] = uigetfile({'*.jpg;*.png;*.bmp;*.tif','Image Files'});
    if file == 0, return; end
    
    try
        % 读取图像
        img = im2double(imread(fullfile(path, file)));
        
        % 存储原始图像数据
        appData.original = img;
        appData.processed = img; % 初始处理图像=原图
        
        %% ===== 统一显示大小逻辑 =====
        % 1. 设置标准尺寸（可根据需要调整）
        maxWidth = 800;
        maxHeight = 600;
        
        % 2. 计算缩放比例
        [height, width, ~] = size(img);
        scaleFactor = min([maxWidth/width, maxHeight/height, 1]); % 限制最大缩放
        
        % 3. 计算统一显示尺寸（保留原始宽高比）
        displayWidth = min(round(width * scaleFactor), maxWidth);
        displayHeight = min(round(height * scaleFactor), maxHeight);
        
        % 存储显示尺寸
        appData.displaySize = [displayHeight, displayWidth];
        appData.originalSize = [height, width];
        guidata(fig, appData);
        
        %% ===== 使用统一尺寸显示原图和结果图 =====
        % 显示原图（使用统一显示尺寸）
        dispImg = imresize(img, [displayHeight, displayWidth]);
        imshow(dispImg, 'Parent', ax1);
        set(ax1, 'Units', 'pixels',...
                 'Position', [1 1 displayWidth displayHeight],...
                 'XLim', [0.5 displayWidth+0.5],...
                 'YLim', [0.5 displayHeight+0.5],...
                 'DataAspectRatio', [1 1 1]);
        
        % 显示处理图像（初始为原图）
        imshow(dispImg, 'Parent', ax2);
        set(ax2, 'Units', 'pixels',...
                 'Position', [1 1 displayWidth displayHeight],...
                 'XLim', [0.5 displayWidth+0.5],...
                 'YLim', [0.5 displayHeight+0.5],...
                 'DataAspectRatio', [1 1 1]);
        
        %% ===== 更新滚动面板内容区域 =====
        % 原图面板
        scrollPanel1.AutoResizeChildren = 'off';
        set(ax1, 'Units', 'pixels', 'Position', [1 1 displayWidth displayHeight]);
        
        % 处理结果面板
        scrollPanel2.AutoResizeChildren = 'off';
        set(ax2, 'Units', 'pixels', 'Position', [1 1 displayWidth displayHeight]);
        
    catch ME
        errordlg(['加载失败: ' ME.message], '错误');
    end
end

%% 保存图像
function saveImage(fig)
    % 获取应用数据
    appData = guidata(fig);
    
    % 检查是否有图像可保存
    if isempty(appData.original) && isempty(appData.processed)
        errordlg('没有图像可保存!', '错误');
        return;
    end
    
    % 确定要保存的图像
    if ~isempty(appData.processed)
        img = appData.processed;
        defaultName = 'processed_image.jpg';
    else
        img = appData.original;
        defaultName = 'original_image.jpg';
    end
    
    % 获取保存路径
    [file, path] = uiputfile({'*.jpg'; '*.png'; '*.bmp'; '*.tif'}, ...
                             '保存图像', defaultName);
    if file == 0, return; end
    
    try
        % 转换图像为可保存格式
        if max(img(:)) <= 1
            imgToSave = im2uint8(img);
        else
            imgToSave = uint8(img);
        end
        
        % 保存图像
        imwrite(imgToSave, fullfile(path, file));
        
        % 显示成功消息
        msgbox(['图像已保存至: ' fullfile(path, file)], '保存成功');
        
    catch ME
        errordlg(['保存失败: ' ME.message], '错误');
    end
end