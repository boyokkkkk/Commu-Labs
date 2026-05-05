clear; clc; close all;

img_matrix = im2bw(imread('sysu_logo.bmp'), 0.5); 
[img_height, img_width] = size(img_matrix);
tx_bits = img_matrix(:)';
num_bits = length(tx_bits);
tx_symbols = 2 * tx_bits - 1;

span = 6; sps = 8; alpha = 0.5;
h_rrc = rcosdesign(alpha, span, sps, 'sqrt');
tx_signal = upfirdn(tx_symbols, h_rrc, sps);

%% 构造信道
current_snr = 8;

% 信道 A：纯高斯白噪声 (AWGN)
rx_signal_awgn = awgn(tx_signal, current_snr, 'measured');

% 信道 B：AWGN + 突发脉冲噪声
impulse_prob = 0.005; 
impulse_amp = 15; % 干扰幅度
impulse_noise = (rand(size(tx_signal)) < impulse_prob) .* impulse_amp .* sign(randn(size(tx_signal)));
rx_signal_burst = rx_signal_awgn + impulse_noise;

%% 接收端处理
decode_signal = @(sig) upfirdn(sig, h_rrc, 1, sps);
extract_bits = @(rx_sym) rx_sym(span + 1 : span + num_bits) > 0;

% 处理信道A
bits_awgn = extract_bits(decode_signal(rx_signal_awgn));
ber_awgn = sum(tx_bits ~= bits_awgn) / num_bits;

% 处理信道B
bits_burst = extract_bits(decode_signal(rx_signal_burst));
ber_burst = sum(tx_bits ~= bits_burst) / num_bits;

%% 可视化结果
figure('Name', '不同类型噪声对图像恢复的影响', 'Position', [100, 100, 900, 350]);

subplot(1,3,1); imshow(img_matrix); title('发送端：原图');
subplot(1,3,2); imshow(reshape(bits_awgn, img_height, img_width)); 
title(sprintf('纯 AWGN (BER=%.4f)', ber_awgn));
subplot(1,3,3); imshow(reshape(bits_burst, img_height, img_width)); 
title(sprintf('AWGN + 突发脉冲 (BER=%.4f)', ber_burst));