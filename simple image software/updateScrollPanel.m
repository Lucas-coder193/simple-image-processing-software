%% 新增函数：updateScrollPanel.m
function updateScrollPanel(panel, img)
    % 更新滚动面板内部坐标轴尺寸
    ax = findobj(panel, 'Type', 'Axes');
    
    % 获取图像尺寸
    imgSize = [size(img,2), size(img,1)];
    
    % 设置坐标轴位置
    set(ax, 'Units', 'pixels',...
            'Position', [1 1 imgSize(1) imgSize(2)]);
    
    % 手动调整面板内容尺寸
    % 重要：确保内容区域=图像尺寸
    panelSize = panel.InnerPosition(3:4); % 获取面板内可用尺寸
    
    % 仅当图像大于面板时才设置滚动
    if any(imgSize > panelSize)
        set(ax, 'Position', [1 1 max(panelSize(1), imgSize(1)) max(panelSize(2), imgSize(2))]);
    else
        % 图像小于面板时仍保持1:1
        set(ax, 'Position', [1 1 imgSize(1) imgSize(2)]);
    end
end