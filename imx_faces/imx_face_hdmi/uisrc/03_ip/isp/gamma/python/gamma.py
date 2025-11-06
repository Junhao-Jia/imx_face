results = []
for i in range(256):
    normalized_value = (i + 0.5) / 256
    gamma = 2.6
    transformed_value = normalized_value ** (1/gamma)
    final_result=transformed_value*4096
    results.append(final_result)

# 打印所有计算结果
for index, value in enumerate(results):
    print(f"{index}: {value}")