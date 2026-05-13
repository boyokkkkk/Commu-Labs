clear; clc; close all;

img_matrix = im2bw(imread('sysu_logo.bmp'), 0.5); 
tx_bits = img_matrix(:)';
num_bits = length(tx_bits);
tx_symbols = 2 * tx_bits - 1;

span = 6; 
fixed_snr = 15; % 设定极高信噪比，排除噪声干扰，只看系统自身成形带来的码间串扰

%% 2. 扫参范围设定
alphas_test = [0.1, 0.3, 0.5, 0.7, 0.9]; % 探究不同的带宽占用
sps_test = [4, 6, 8, 12]; % 探究不同的过采样率（越小代表物理传输速率越快）
BER_matrix = zeros(length(alphas_test), length(sps_test));

for i = 1:length(alphas_test)
    for j = 1:length(sps_test)
        current_alpha = alphas_test(i);
        current_sps = sps_test(j);
        
        % 重新生成当前参数下的滤波器并成形
        h_rrc = rcosdesign(current_alpha, span, current_sps, 'sqrt');
        tx_signal = upfirdn(tx_symbols, h_rrc, current_sps);
        
        rx_signal = awgn(tx_signal, fixed_snr, 'measured');
        
        % 计算 30% 周期对应的采样点数（四舍五入）
        jitter_samples = round(current_sps * 0.3); 
        % 使用 [0, jitter_samples] 确保在行向量上做水平循环移位
        rx_signal_jitter = circshift(rx_signal, [0, jitter_samples]); 
        
        % 接收判决
        rx_symbols_filtered = upfirdn(rx_signal_jitter, h_rrc, 1, current_sps);
        rx_symbols_sync = rx_symbols_filtered(span + 1 : span + num_bits);
        rx_bits = rx_symbols_sync > 0;
        
        BER_matrix(i, j) = sum(tx_bits ~= rx_bits) / num_bits;
    end
end

%% 热力图
figure('Name', '带宽与速率分析', 'Position', [200, 200, 600, 500]);
imagesc(1:length(sps_test), 1:length(alphas_test), BER_matrix);
colorbar;
colormap(flipud(hot)); % 颜色越深(红/黑)误码率越高，越亮(白/黄)越好

% 设置坐标轴标签
set(gca, 'XTick', 1:length(sps_test), 'XTickLabel', sps_test);
set(gca, 'YTick', 1:length(alphas_test), 'YTickLabel', alphas_test);
xlabel('过采样率 SPS (数值越小，等效传输速率越快)');
ylabel('滚降系数 \alpha (数值越小，占用带宽越窄)');
title('BER 热力图');

% 在色块上标记具体数值
for i = 1:length(alphas_test)
    for j = 1:length(sps_test)
        text(j, i, sprintf('%.4f', BER_matrix(i, j)), ...
            'HorizontalAlignment', 'center', 'Color', 'cyan', 'FontWeight', 'bold');
    end
end