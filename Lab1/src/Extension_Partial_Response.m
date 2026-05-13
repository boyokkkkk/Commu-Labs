%% ===================== PR1 部分响应系统（数学正确版） =====================
clear; clc; close all;

%% 参数
SNR = 10;
sps = 8;

%% 读取图像
img = imread('sysu_logo.bmp');
img = im2bw(img, 0.5);
[h, w] = size(img);
tx_bits = double(img(:)');
N = length(tx_bits);
fprintf('图像大小: %d x %d = %d bits\n', h, w, N);

%% ========== 发送端 ==========
% 步骤1: 预编码 d_k = x_k ⊕ d_{k-1}
d = zeros(1, N);
d(1) = tx_bits(1);
for k = 2:N
    d(k) = xor(tx_bits(k), d(k-1));
end

% 步骤2: 双极性映射 a_k = 2*d_k - 1  (0→-1, 1→+1)
a = 2*d - 1;

% 步骤3: PR1编码 c_k = a_k + a_{k-1} (设a_0 = 0)
c = zeros(1, N);
c(1) = a(1);  % a_1 + a_0
for k = 2:N
    c(k) = a(k) + a(k-1);
end
% c_k ∈ {-2, 0, +2}

% 发送（矩形脉冲）
tx_signal = reshape(repmat(c, sps, 1), 1, N*sps);

%% ========== 信道 ==========
rx_signal = awgn(tx_signal, SNR, 'measured');

%% ========== 接收端 ==========
% 采样
% 接收端加匹配滤波器
% 1. 匹配滤波
matched_filter = ones(1, sps) / sps;  % 归一化！
rx_filtered = filter(matched_filter, 1, rx_signal);

% 2. 正确采样点（重要！）
% 矩形脉冲的最佳采样点在每个符号周期的末端
rx_c = rx_filtered(sps : sps : end);  % 注意是sps，不是sps/2

% ✅ 正确译码步骤：
% 1. 判决 d_k (不是直接判a_k!)
%    规则：d_k = 1 if c_k > 0, d_k = 0 if c_k < 0
%          if c_k = 0, d_k = NOT d_{k-1}
rx_d = zeros(1, N);

threshold = 0.8;
for k = 1:N
    if rx_c(k) > threshold      % 正电平 → +2
        rx_d(k) = 1;
    elseif rx_c(k) < -threshold % 负电平 → -2
        rx_d(k) = 0;
    else                  % 接近0
        if k == 1
            rx_d(k) = 0;  % 假设初始
        else
            rx_d(k) = ~rx_d(k-1);  % 关键！c_k=0时，d_k翻转
        end
    end
end

% 2. 恢复原始比特 x_k = d_k ⊕ d_{k-1}
rx_bits = zeros(1, N);
rx_bits(1) = rx_d(1);  % x_1 = d_1 ⊕ d_0, d_0=0
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
    rx_c_test = rx_test(sps/2 : sps : end);
    
    % 译码
    rx_d_test = zeros(1, N);
    for k = 1:N
        if rx_c_test(k) > 0.5
            rx_d_test(k) = 1;
        elseif rx_c_test(k) < -0.5
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