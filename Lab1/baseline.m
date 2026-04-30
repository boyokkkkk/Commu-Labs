% =========================================================================
% 默认配置：双极性NRZ码 + 根升余弦滤波 + AWGN信道 + 10dB SNR
% =========================================================================
clear; clc; close all;

%% 1. 系统参数配置
SNR = 10;               % 信噪比 (dB)
alpha = 0.5;            % 升余弦滤波器的滚降系数
span = 6;               % 滤波器的截断长度(符号数)
sps = 8;                % 每个符号的采样点数 (过采样率)

%% 2. 信源读取与预处理 
img_matrix = imread('sysu_logo.bmp'); 
img_matrix = im2bw(img_matrix, 0.5); % 转为二值图
[img_height, img_width] = size(img_matrix);

% 将二维图像矩阵展平为一维的发送比特流
tx_bits = img_matrix(:)'; 
num_bits = length(tx_bits);

%% 3. 基带调制：双极性不归零码
% 映射规则: 0 -> -1, 1 -> +1
tx_symbols = 2 * tx_bits - 1;

%% 4. 发送端脉冲成形 (根升余弦滤波)
rrc_filter = rcosdesign(alpha, span, sps, 'sqrt');
tx_signal = upfirdn(tx_symbols, rrc_filter, sps);

%% 5. 信道传输 (加入高斯白噪声)
rx_signal = awgn(tx_signal, SNR, 'measured');

%% 6. 接收端匹配滤波与抽样
rx_symbols_filtered = upfirdn(rx_signal, rrc_filter, 1, sps);

rx_symbols_sync = rx_symbols_filtered(span + 1 : span + num_bits);

%% 7. 信号判决
% 对于双极性码，判决门限为 0
rx_bits = rx_symbols_sync > 0;

%% 8. 误码率计算与图像恢复
% 计算误码率 (BER)
num_errors = sum(tx_bits ~= rx_bits);
BER = num_errors / num_bits;
fprintf('当前信噪比 SNR = %d dB, 误码率 BER = %e\n', SNR, BER);

% 将一维比特流重组为二维图像矩阵
rx_img_matrix = reshape(rx_bits, img_height, img_width);

%% 9. 结果可视化展示
figure('Name', '通信原理基线系统仿真', 'Position', [100, 100, 900, 400]);

% 1. 显示发送端原图
subplot(1, 3, 1);
imshow(img_matrix);
title('发送端: 原始图像');

% 2. 接收端眼图 (截取部分信号展示)
subplot(1, 3, 2);
% 提取经过匹配滤波但未抽样的信号来画眼图
eyediagram_signal = upfirdn(rx_signal, rrc_filter); 
% 截取中间段信号画眼图，避免边缘效应
eyediagram(eyediagram_signal(sps*span+1 : sps*span+1000), sps*2);
title('接收端: 信号眼图');

% 3. 显示接收端恢复图像
subplot(1, 3, 3);
imshow(rx_img_matrix);
title(['接收端: 恢复图像 (BER=', num2str(BER, '%0.4f'), ')']);