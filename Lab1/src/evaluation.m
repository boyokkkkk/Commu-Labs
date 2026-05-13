clear; clc; close all;

%% --- 0. 准备测试图片 ---
img_matrix = imread('sysu_logo.bmp'); 
img_matrix = im2bw(img_matrix, 0.5); % 转为二值图
[img_height, img_width] = size(img_matrix);

% 将二维图像矩阵展平为一维的发送比特流
tx_bits = img_matrix(:)'; 
num_bits = length(tx_bits);

% 基带调制
tx_symbols = 2 * tx_bits - 1;

% 基础系统参数
span = 6; 
sps = 8; 

%% =========================================================================
% 实验1：扫噪声 (评估信噪比对误码率及图像的影响)
% =========================================================================
SNRs_test = 0:2:12;  % 遍历的 SNR 范围
BER_results = zeros(1, length(SNRs_test));
alpha_base = 0.5;    % 实验1固定滚降系数为 0.5

% 生成滤波器
h_rrc_base = rcosdesign(alpha_base, span, sps, 'sqrt');
tx_signal_base = upfirdn(tx_symbols, h_rrc_base, sps);

figure('Name', '实验1：不同信噪比下的图像恢复对比', 'Position', [100, 100, 800, 600]);
plot_idx = 1;

for i = 1:length(SNRs_test)
    current_snr = SNRs_test(i);
    
    % 信道与接收判决
    rx_signal = awgn(tx_signal_base, current_snr, 'measured');
    rx_symbols_filtered = upfirdn(rx_signal, h_rrc_base, 1, sps);
    rx_symbols_sync = rx_symbols_filtered(span + 1 : span + num_bits);
    rx_bits = rx_symbols_sync > 0;
    
    % 计算 BER
    BER_results(i) = sum(tx_bits ~= rx_bits) / num_bits;
    
    % 挑选几个典型的 SNR 绘制恢复图像对比图 (例如 0, 4, 8, 12 dB)
    if ismember(current_snr, [0, 4, 8, 12])
        subplot(2, 2, plot_idx);
        rx_img_matrix = reshape(rx_bits, img_height, img_width);
        imshow(rx_img_matrix);
        title(sprintf('SNR = %d dB, BER = %.4f', current_snr, BER_results(i)));
        plot_idx = plot_idx + 1;
    end
end

% 绘制 BER-SNR 瀑布曲线
figure('Name', '实验1：BER vs SNR 曲线', 'Position', [150, 150, 500, 400]);
semilogy(SNRs_test, BER_results, '-bo', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
grid on;
xlabel('信噪比 SNR (dB)'); ylabel('误码率 BER');
title('高斯白噪声信道下系统抗噪性能曲线');

%% =========================================================================
% 实验2：扫系统带宽/滚降系数 (评估成形滤波器的影响)
% 理论支持：带宽 B = (Rs / 2) * (1 + alpha)
% =========================================================================
alphas_test = [0.1, 0.5, 0.9]; % 极小、中等、极大三个滚降系数对比
fixed_snr = 20; % 实验2固定一个较高的SNR，以便清晰观察眼图的码间串扰(ISI)

figure('Name', '实验2：不同滚降系数(带宽)对眼图的影响', 'Position', [200, 200, 1000, 300]);

for i = 1:length(alphas_test)
    current_alpha = alphas_test(i);
    
    % 根据不同的 alpha 重新生成滤波器
    h_rrc_test = rcosdesign(current_alpha, span, sps, 'sqrt');
    tx_signal_test = upfirdn(tx_symbols, h_rrc_test, sps);
    
    % 经过固定噪声信道
    rx_signal_test = awgn(tx_signal_test, fixed_snr, 'measured');
    
    % 匹配滤波 (用于画眼图的未抽样信号)
    eye_signal = upfirdn(rx_signal_test, h_rrc_test);
    
    % --- 手写眼图绘制逻辑 (避免 MATLAB eyediagram 函数疯狂弹窗) ---
    subplot(1, 3, i);
    hold on;
    % 截取中间段信号避免边缘效应，每次画 2 个符号周期 (2*sps 个采样点)
    offset = sps * span * 2; 
    num_traces = 200; % 叠加 200 条轨迹
    for k = 1:num_traces
        start_idx = offset + (k-1)*sps + 1;
        end_idx = start_idx + 2*sps;
        plot(0 : 2*sps, eye_signal(start_idx : end_idx), 'b');
    end
    hold off;
    
    % 计算理论占用带宽比例 (假设奈奎斯特带宽 Rs/2 为 1)
    bw_ratio = 1 + current_alpha; 
    
    title(sprintf('\\alpha = %.1f (相对带宽: %.1f)', current_alpha, bw_ratio));
    xlabel('采样点'); ylabel('幅度');
    axis([0, 2*sps, -1.5, 1.5]);
    grid on;
end