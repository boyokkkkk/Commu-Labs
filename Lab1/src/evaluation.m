clear; clc;

disp('==============================================');
disp('Task B: 探究噪声变化与码元速率对图像恢复质量的影响');
disp('==============================================');

%% 任务一：突发脉冲概率扫描
disp('>> 正在执行 S1: 噪声类型与破坏性评估...');
snr_base = 8;
amp_base = 15;
probs_to_test = [0.001, 0.005, 0.01, 0.05]; % 测试不同概率的突发噪声
for p = probs_to_test
    fprintf('   - 正在渲染概率结果图片 %.3f ...\n', p);
    s1_noise_types(snr_base, p, amp_base);
end
disp('   [√] S1 结果已存入 result/B_s1 文件夹');

%% 任务二：蒙特卡洛统计置信度扫描
disp('>> 正在执行 S2: 蒙特卡洛瀑布曲线评估...');
target_errs = 100;
max_bits_test = [1e5, 1e6, 5e6]; % 测试低置信度到高置信度的表现
for mb = max_bits_test
    fprintf('   - 正在运算 MaxBits = %1.0e ...\n', mb);
    s2_noise_changes(target_errs, mb);
end
disp('   [√] S2 结果已存入 result/B_s2 文件夹');

%% 任务三：定时误差容忍度热力图扫描
disp('>> 正在执行 S3: 带宽与速率博弈评估...');
jitter_ratios = [0.1, 0.2, 0.4]; % 测试 10%, 20%, 40% 的时钟抖动偏差
for j = jitter_ratios
    fprintf('   - 正在运算抖动比例 %.0f%% ...\n', j * 100);
    s3_bandwidth_and_rate(j);
end
disp('   [√] S3 结果已存入 result/B_s3 文件夹');

disp('=========================================');
disp('     测试完毕！请查看 result 文件夹');
disp('=========================================');