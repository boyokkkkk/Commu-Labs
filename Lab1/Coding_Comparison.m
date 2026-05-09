clear; clc; close all;

%% ======================== 【从B同学复制来的公共系统参数】=========================
SNR = 1;                   % 固定噪声
alpha = 0.5;               % 滚降系数
span = 6;                  % 滤波器符号数
sps = 8;                   % 过采样率

%% ======================== 【从B同学复制来的图像读取 + 比特流】=====================
img_matrix = imread('sysu_logo.bmp'); 
img_matrix = im2bw(img_matrix, 0.5); 
[img_height, img_width] = size(img_matrix);
tx_bits = img_matrix(:)'; 
num_bits = length(tx_bits);
tx_bits = double(tx_bits);

%% ======================== 【从B同学复制来的升余弦滤波器】=========================
rrc_filter = rcosdesign(alpha, span, sps, 'sqrt');

%% ========================== 1. 单极性 不归零 NRZ =============================
sym_unipolar_nrz = tx_bits;
tx_wave = upfirdn(sym_unipolar_nrz, rrc_filter, sps);
rx_wave = awgn(tx_wave, SNR, 'measured');
rx_filt = upfirdn(rx_wave, rrc_filter, 1, sps);
rx_samp = rx_filt(span+1 : span+num_bits);
bits_unipolar_nrz = rx_samp > 0.5;
BER_unipolar_nrz = sum(tx_bits ~= bits_unipolar_nrz) / num_bits;

%% ========================== 2. 单极性 归零 RZ  ==============================
sym_unipolar_rz = zeros(1, num_bits);
for i = 1:num_bits
    sym_unipolar_rz(i) = tx_bits(i);
end
tx_wave = upfirdn(sym_unipolar_rz, rrc_filter, sps);
rx_wave = awgn(tx_wave, SNR, 'measured');
rx_filt = upfirdn(rx_wave, rrc_filter, 1, sps);
rx_samp = rx_filt(span+1 : span+num_bits);
bits_unipolar_rz = rx_samp > 0.5;
BER_unipolar_rz = sum(tx_bits ~= bits_unipolar_rz) / num_bits;

%% ========================== 3. 双极性 不归零 NRZ =============================
sym_bipolar_nrz = 2 * tx_bits - 1;
tx_wave = upfirdn(sym_bipolar_nrz, rrc_filter, sps);
rx_wave = awgn(tx_wave, SNR, 'measured');
rx_filt = upfirdn(rx_wave, rrc_filter, 1, sps);
rx_samp = rx_filt(span+1 : span+num_bits);
bits_bipolar_nrz = rx_samp > 0;
BER_bipolar_nrz = sum(tx_bits ~= bits_bipolar_nrz) / num_bits;

%% ========================== 4. 双极性 归零 RZ  ==============================
sym_bipolar_rz = 2 * tx_bits - 1;
tx_wave = upfirdn(sym_bipolar_rz, rrc_filter, sps);
rx_wave = awgn(tx_wave, SNR, 'measured');
rx_filt = upfirdn(rx_wave, rrc_filter, 1, sps);
rx_samp = rx_filt(span+1 : span+num_bits);
bits_bipolar_rz = rx_samp > 0;
BER_bipolar_rz = sum(tx_bits ~= bits_bipolar_rz) / num_bits;

%% ========================== 5. 差分码 =============================
sym_diff = zeros(1, num_bits);
sym_diff(1) = tx_bits(1);
for i = 2:num_bits
    sym_diff(i) = xor(sym_diff(i-1), tx_bits(i));
end
sym_diff = 2 * sym_diff - 1;
tx_wave = upfirdn(sym_diff, rrc_filter, sps);
rx_wave = awgn(tx_wave, SNR, 'measured');
rx_filt = upfirdn(rx_wave, rrc_filter, 1, sps);
rx_samp = rx_filt(span+1 : span+num_bits);
rx_bin = rx_samp > 0;
bits_diff = zeros(1, num_bits);
bits_diff(1) = rx_bin(1);
for i = 2:num_bits
    bits_diff(i) = xor(rx_bin(i-1), rx_bin(i));
end
BER_diff = sum(tx_bits ~= bits_diff) / num_bits;

%% ======================== 图像恢复 ============================
img_original = reshape(tx_bits, img_height, img_width);
img_unipolar_nrz = reshape(bits_unipolar_nrz, img_height, img_width);
img_unipolar_rz  = reshape(bits_unipolar_rz, img_height, img_width);
img_bipolar_nrz  = reshape(bits_bipolar_nrz, img_height, img_width);
img_bipolar_rz   = reshape(bits_bipolar_rz, img_height, img_width);
img_diff         = reshape(bits_diff, img_height, img_width);

%% ======================== 输出所有 BER ============================
fprintf('===== 五种编码对比结果 =====\n');
fprintf('单极性 NRZ   BER = %.6f\n', BER_unipolar_nrz);
fprintf('单极性 RZ    BER = %.6f\n', BER_unipolar_rz);
fprintf('双极性 NRZ   BER = %.6f\n', BER_bipolar_nrz);
fprintf('双极性 RZ    BER = %.6f\n', BER_bipolar_rz);
fprintf('差分码       BER = %.6f\n', BER_diff);

%% ======================== 画图 ============================
figure;
subplot(3,2,1); imshow(img_original);        title('原始图像');
subplot(3,2,2); imshow(img_unipolar_nrz);    title(['单极性NRZ  BER=' num2str(BER_unipolar_nrz,'%.4f')]);
subplot(3,2,3); imshow(img_unipolar_rz);     title(['单极性RZ   BER=' num2str(BER_unipolar_rz,'%.4f')]);
subplot(3,2,4); imshow(img_bipolar_nrz);     title(['双极性NRZ  BER=' num2str(BER_bipolar_nrz,'%.4f')]);
subplot(3,2,5); imshow(img_bipolar_rz);      title(['双极性RZ   BER=' num2str(BER_bipolar_rz,'%.4f')]);
subplot(3,2,6); imshow(img_diff);            title(['差分码      BER=' num2str(BER_diff,'%.4f')]);