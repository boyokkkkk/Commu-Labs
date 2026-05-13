clear; clc; close all;

span = 6; sps = 8; alpha = 0.5;
h_rrc = rcosdesign(alpha, span, sps, 'sqrt');

% 扫参设置
SNRs_test = 0:0.5:6;  
BER_results = zeros(1, length(SNRs_test));

% 蒙特卡洛统计参数
target_errors = 100;    % 每个信噪比下，必须收集到 100 个错码才停止
max_bits = 1e6;         % 设置一个最高发送上限(100万比特)，防止高信噪比下死循环
bits_per_frame = 10000; % 每次发送一帧（一万个比特）

disp('开始蒙特卡洛仿真，可能需要几分钟，请耐心等待...');

for i = 1:length(SNRs_test)
    current_snr = SNRs_test(i);
    total_errors = 0;
    total_bits = 0;
    
    while (total_errors < target_errors) && (total_bits < max_bits)
        % 1. 动态生成随机比特流代替图片
        tx_bits = randi([0 1], 1, bits_per_frame);
        tx_symbols = 2 * tx_bits - 1;
        
        % 2. 通信链路
        tx_signal = upfirdn(tx_symbols, h_rrc, sps);
        rx_signal = awgn(tx_signal, current_snr, 'measured');
        rx_symbols_filtered = upfirdn(rx_signal, h_rrc, 1, sps);
        rx_symbols_sync = rx_symbols_filtered(span + 1 : span + bits_per_frame);
        rx_bits = rx_symbols_sync > 0;
        
        % 3. 累计错误
        frame_errors = sum(tx_bits ~= rx_bits);
        total_errors = total_errors + frame_errors;
        total_bits = total_bits + bits_per_frame;
    end
    
    BER_results(i) = total_errors / total_bits;
    fprintf('SNR = %.1f dB | 传输总比特: %d | 累计错码: %d | BER = %e\n', ...
            current_snr, total_bits, total_errors, BER_results(i));
end

figure('Name', '系统抗噪性能曲线', 'Position', [150, 150, 600, 500]);

% 核心技巧：提取所有误码率大于 0 的有效数据点
valid_idx = BER_results > 0; 
valid_SNRs = SNRs_test(valid_idx);
valid_BERs = BER_results(valid_idx);

% 只绘制有效数据
semilogy(valid_SNRs, valid_BERs, '-ro', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
grid on;

xlabel('信噪比 SNR (dB)'); 
ylabel('误码率 BER');
title('高斯白噪声信道下 BER-SNR 曲线 (蒙特卡洛仿真)');

% 动态设置 Y 轴下限，让曲线刚好触底
ylim([min(valid_BERs)/2, 1]);