%% UI组件模块：createUIComponents.m
function createUIComponents(fig)
    % ===== 创建可滚动的显示面板 =====
    % 原始图像面板（带滚动条）
    scrollPanel1 = uipanel(fig, 'Position', [20 100 450 450],...
                         'BorderType', 'none',...
                         'Scrollable', 'on',...
                         'Tag', 'OriginalScrollPanel');
    
    % 处理结果面板（带滚动条）
    scrollPanel2 = uipanel(fig, 'Position', [530 100 450 450],...
                         'BorderType', 'none',...
                         'Scrollable', 'on',...
                         'Tag', 'ProcessedScrollPanel');
    
    % ===== 在面板内创建坐标轴 =====
    ax1 = uiaxes('Parent', scrollPanel1,...
                'Units', 'normalized',...
                'Position', [0 0 1 1],... % 充满整个面板
                'Tag', 'OriginalAxes');
            
    ax2 = uiaxes('Parent', scrollPanel2,...
                'Units', 'normalized',...
                'Position', [0 0 1 1],...
                'Tag', 'ProcessedAxes');
    
    % ===== 设置坐标轴属性 =====
    set([ax1, ax2], 'DataAspectRatio', [1 1 1],... % 保持宽高比
                   'XTick', [],...             % 隐藏刻度
                   'YTick', []);
    
    %% 布局参数定义
    btnWidth = 90;        % 按钮宽度
    btnHeight = 30;       % 按钮高度
    horizontalGap = 15;   % 水平间距
    verticalGap = 20;      % 垂直间距
    startX = 20;          % 起始X坐标
    btnY1 = 20;           % 第一行Y坐标
    btnY2 = btnY1 + btnHeight + verticalGap;  % 第二行Y坐标
    
    %% 第一行按钮（基础操作+核心功能）
    % 打开图像 - 使用统一入口函数
    uibutton(fig, 'Text','打开图像','Position', [startX btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) fileOperations('load', fig));
    
    % 保存结果 - 使用统一入口函数
    uibutton(fig, 'Text','保存图像','Position', [startX+(btnWidth+horizontalGap)*1 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) fileOperations('save', fig));
    
    % 以下按钮保持不变...
    uibutton(fig, 'Text','图像缩放','Position', [startX+(btnWidth+horizontalGap)*2 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @scaleImageCustom));
    
    uibutton(fig, 'Text','图像增强','Position', [startX+(btnWidth+horizontalGap)*3 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @enhanceImage));
    
    uibutton(fig, 'Text','颜色变换','Position', [startX+(btnWidth+horizontalGap)*4 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @colorTransform));
    
    uibutton(fig, 'Text','滤镜处理','Position', [startX+(btnWidth+horizontalGap)*5 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @filterModule));
    
    uibutton(fig, 'Text','图像分割','Position', [startX+(btnWidth+horizontalGap)*6 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @segmentModule));
    
    uibutton(fig, 'Text','图像识别','Position', [startX+(btnWidth+horizontalGap)*7 btnY1 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @recognizeModule));
    
    %% 第二行按钮（高级处理）
    % 直方图均衡
    uibutton(fig, 'Text','直方图均衡','Position', [startX btnY2 btnWidth btnHeight],'ButtonPushedFcn', @(src,event) processImage(fig, @histeqCustom));
    
end