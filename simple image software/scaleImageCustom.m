%% 图像缩放模块：scaleImageCustom.m
function [output, scale] = scaleImageCustom(input)
    % 获取缩放参数
    answer = inputdlg({'缩放因子 (0.1-5.0):'}, '图像缩放', [1 35], {'1.0'});
    if isempty(answer)
        output = input; scale = 1; return;
    end
    
    try
        scale = str2double(answer{1});
        validateattributes(scale, {'numeric'}, {'>=',0.1, '<=',5});
        
        % 精确尺寸控制
        [h,w,~] = size(input);
        
        % ========== 关键修复：移除1.1倍缓冲 ==========
        if abs(scale - 1) < 0.001
            output = input; % 缩放因子为1时直接返回原图
        else
            % 精确计算新尺寸
            newH = max(1, round(h*scale));
            newW = max(1, round(w*scale));
            output = imresize(input, [newH newW]);
        end
        
    catch ME
        errordlg(['缩放失败: ' ME.message], '错误');
        output = input; scale = 1;
    end
end