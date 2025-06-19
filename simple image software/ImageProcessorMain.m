%% 主程序文件：ImageProcessorMain.m
function ImageProcessorMain
    % 创建主界面
    fig = uifigure('Name', '图像处理器', 'Position', [100 100 1000 600]);
    
    % 初始化图像数据存储
    appData.original = [];
    appData.processed = [];
    guidata(fig, appData);
    
    % 创建UI组件
    createUIComponents(fig);
end