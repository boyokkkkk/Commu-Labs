function s3_bandwidth_and_rate(jitter_ratio)
    %% s3: 带宽与速率在不同抖动比例下的博弈热力图
    num_bits = 500000; % 使用五十万个比特保证热力图平滑
    tx_bits = randi([0 1], 1, num_bits);
    tx_symbols = 2 * tx_bits - 1;
    span = 6; fixed_snr = 20; 

    alphas_test = [0.1, 0.3, 0.5, 0.7, 0.9]; 
    sps_test = [4, 6, 8, 12, 16]; 
    BER_matrix = zeros(length(alphas_test), length(sps_test));

    for i = 1:length(alphas_test)
        for j = 1:length(sps_test)
            h_rrc = rcosdesign(alphas_test(i), span, sps_test(j), 'sqrt');
            tx_signal = upfirdn(tx_symbols, h_rrc, sps_test(j));
            rx_signal = awgn(tx_signal, fixed_snr, 'measured');
            
            % 核心控制变量：动态定时抖动
            jitter_samples = floor(sps_test(j) * jitter_ratio); 
            rx_signal_jitter = circshift(rx_signal, [0, jitter_samples]); 
            
            rx_symbols_filtered = upfirdn(rx_signal_jitter, h_rrc, 1, sps_test(j));
            rx_symbols_sync = rx_symbols_filtered(span + 1 : span + num_bits);
            BER_matrix(i, j) = sum(tx_bits ~= (rx_symbols_sync > 0)) / num_bits;
        end
    end

    %% 绘图
    plot_BER = BER_matrix;
    plot_BER(plot_BER == 0) = 1e-6; 

    fig = figure('Visible', 'off', 'Position', [200, 200, 700, 550]);
    imagesc(1:length(sps_test), 1:length(alphas_test), log10(plot_BER));
    c = colorbar; c.Ticks = -6:-1; c.TickLabels = {'10^{-6}', '10^{-5}', '10^{-4}', '10^{-3}', '10^{-2}', '10^{-1}'};
    colormap(flipud(hot)); clim([-6, -1]); 
    set(gca, 'XTick', 1:length(sps_test), 'XTickLabel', sps_test, 'YTick', 1:length(alphas_test), 'YTickLabel', alphas_test);
    xlabel('过采样率 SPS'); ylabel('滚降系数 \alpha');
    title(sprintf('BER热力图 (定时误差比例: %.0f%%)', jitter_ratio * 100));

    for i = 1:length(alphas_test)
        for j = 1:length(sps_test)
            txt_color = ifelse(BER_matrix(i, j) > 1e-3, 'white', 'cyan');
            text(j, i, sprintf('%.4f', BER_matrix(i, j)), 'HorizontalAlignment', 'center', 'Color', txt_color, 'FontWeight', 'bold');
        end
    end

    if ~exist('result/B_s3', 'dir'), mkdir('result/B_s3'); end
    filename = sprintf('result/B_s3/Heatmap_Jitter%.2f.png', jitter_ratio);
    exportgraphics(fig, filename, 'Resolution', 300);
    close(fig);
end

function res = ifelse(cond, a, b) % 辅助三元操作函数
    if cond, res = a; else, res = b; end
end