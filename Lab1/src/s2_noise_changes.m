function s2_noise_changes(target_errors, max_bits)
    %% s2: 蒙特卡洛高密度瀑布曲线
    span = 6; sps = 8; alpha = 0.5;
    h_rrc = rcosdesign(alpha, span, sps, 'sqrt');
    SNRs_test = 0:0.5:6;  
    BER_results = zeros(1, length(SNRs_test));
    bits_per_frame = 10000; 

    for i = 1:length(SNRs_test)
        current_snr = SNRs_test(i);
        total_errors = 0; total_bits = 0;
        
        while (total_errors < target_errors) && (total_bits < max_bits)
            tx_bits = randi([0 1], 1, bits_per_frame);
            tx_symbols = 2 * tx_bits - 1;
            tx_signal = upfirdn(tx_symbols, h_rrc, sps);
            rx_signal = awgn(tx_signal, current_snr, 'measured');
            rx_symbols_filtered = upfirdn(rx_signal, h_rrc, 1, sps);
            rx_symbols_sync = rx_symbols_filtered(span + 1 : span + bits_per_frame);
            rx_bits = rx_symbols_sync > 0;
            
            total_errors = total_errors + sum(tx_bits ~= rx_bits);
            total_bits = total_bits + bits_per_frame;
        end
        BER_results(i) = total_errors / total_bits;
    end

    %% 绘图
    fig = figure('Visible', 'off', 'Position', [150, 150, 600, 500]);
    valid_idx = BER_results > 0; 
    semilogy(SNRs_test(valid_idx), BER_results(valid_idx), '-ro', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'r');
    grid on; xlabel('SNR (dB)'); ylabel('BER');
    title(sprintf('BER瀑布曲线 (MaxBits=%1.0e, TargetErr=%d)', max_bits, target_errors));
    ylim([min(BER_results(valid_idx))/2, 1]);

    if ~exist('result/B_s2', 'dir'), mkdir('result/B_s2'); end
    filename = sprintf('result/B_s2/Waterfall_MaxBits%1.0e_Err%d.png', max_bits, target_errors);
    exportgraphics(fig, filename, 'Resolution', 300);
    close(fig);
end