%% ===================== PR1 部分响应系统 =====================
clear; clc; close all;

%% 参数
SNR = 5;
sps = 8;

%% 读取图像
img = imread('sysu_logo.bmp');
img = im2bw(img, 0.5);
[h, w] = size(img);
tx_bits = double(img(:)');
N = length(tx_bits);
fprintf('图像大小: %d x %d = %d bits\n', h, w, N);

%% ========== 发送端 ==========
% 预编码
d = zeros(1, N);
d(1) = tx_bits(1);
for k = 2:N
    d(k) = xor(tx_bits(k), d(k-1));
end

% 双极性映射
a = 2*d - 1;

% PR1编码
c = zeros(1, N);
c(1) = a(1);
for k = 2:N
    c(k) = a(k) + a(k-1);
end

% 发送（矩形脉冲）
tx_signal = reshape(repmat(c, sps, 1), 1, N*sps);

%% ========== 信道 ==========
rx_signal = awgn(tx_signal, SNR, 'measured');

%% ========== 接收端（匹配滤波） ==========
% 匹配滤波器
matched_filter = ones(1, sps) / sps;
rx_filtered = filter(matched_filter, 1, rx_signal);

% 末端采样
rx_c = rx_filtered(sps : sps : end);

% 译码
rx_d = zeros(1, N);
threshold = 0.8;
for k = 1:N
    if rx_c(k) > threshold
        rx_d(k) = 1;
    elseif rx_c(k) < -threshold
        rx_d(k) = 0;
    else
        if k == 1
            rx_d(k) = 0;
        else
            rx_d(k) = ~rx_d(k-1);
        end
    end
end

% 差分译码
rx_bits = zeros(1, N);
rx_bits(1) = rx_d(1);
for k = 2:N
    rx_bits(k) = xor(rx_d(k), rx_d(k-1));
end

%% ========== 计算BER ==========
BER = sum(tx_bits ~= rx_bits) / N;
fprintf('SNR = %d dB, BER = %.6f\n', SNR, BER);

%% ========== 显示结果 ==========
rx_img = reshape(rx_bits, h, w);
figure;
subplot(1,2,1); imshow(img); title('原始图像');
subplot(1,2,2); imshow(rx_img); title(sprintf('PR1恢复 (BER=%.4f)', BER));

%% ========== 性能曲线 ==========
figure;
snr_range = 0:2:12;
ber_curve = zeros(size(snr_range));

for idx = 1:length(snr_range)
    snr_test = snr_range(idx);
    rx_test = awgn(tx_signal, snr_test, 'measured');
    
    % 匹配滤波
    rx_filtered_test = filter(matched_filter, 1, rx_test);
    rx_c_test = rx_filtered_test(sps : sps : end);
    
    % 译码
    rx_d_test = zeros(1, N);
    for k = 1:N
        if rx_c_test(k) > 0.8
            rx_d_test(k) = 1;
        elseif rx_c_test(k) < -0.8
            rx_d_test(k) = 0;
        else
            if k == 1
                rx_d_test(k) = 0;
            else
                rx_d_test(k) = ~rx_d_test(k-1);
            end
        end
    end
    
    rx_bits_test = zeros(1, N);
    rx_bits_test(1) = rx_d_test(1);
    for k = 2:N
        rx_bits_test(k) = xor(rx_d_test(k), rx_d_test(k-1));
    end
    
    ber_curve(idx) = sum(tx_bits ~= rx_bits_test) / N;
end

semilogy(snr_range, ber_curve, 'b-o', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('PR1 部分响应系统性能');