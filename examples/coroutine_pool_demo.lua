require("init")
local copool = require("coroutine_pool")

-- 测试函数

-- 1. 无参数，单返回值
local function simpleCalculation()
    return 42
end

-- 2. 单参数，多返回值
local function divideAndRemainder(n)
    return math.floor(n / 2), n % 2
end

-- 3. 多参数，单返回值
local function weightedSum(a, b, c, weightA, weightB, weightC)
    return a * weightA + b * weightB + c * weightC
end

-- 4. 多参数，多返回值
local function statsCalculator(...)
    local numbers = { ... }
    local sum = 0
    local max = numbers[1] or 0
    local min = numbers[1] or 0

    for _, v in ipairs(numbers) do
        sum = sum + v
        max = math.max(max, v)
        min = math.min(min, v)
    end

    local avg = sum / #numbers
    return avg, max, min, #numbers
end

-- 5. 字符串处理，多参数，多返回值
local function processString(str, separator)
    local parts = {}
    for part in string.gmatch(str, "([^" .. separator .. "]+)") do
        table.insert(parts, part)
    end
    return #parts, table.concat(parts, " "), string.upper(str)
end

-- 6. 复杂计算，可变参数，多返回值
local function complexCalculation(operation, ...)
    local numbers = { ... }
    if operation == "sum" then
        local sum = 0
        for _, v in ipairs(numbers) do sum = sum + v end
        return sum, "sum calculated"
    elseif operation == "product" then
        local product = 1
        for _, v in ipairs(numbers) do product = product * v end
        return product, "product calculated"
    else
        return nil, "unknown operation", #numbers
    end
end

-- 7. 嵌套协程
local function simulateAsyncOperation(delay, ...)
    local args = { ... }

    copool.execute(function()
        print("Async operation started")
        copool.execute(function()
            print(" - Nested async operation started")
            copool.execute(function()
                print("  * Deeply nested async operation started")
                print("  * Deeply nested async operation complete")
            end)
            print(" - Nested async operation complete")
        end)
        print("Async operation complete")
    end)
    return "Operation complete", #args, table.unpack(args)
end

-- 测试执行
print("1. Simple Calculation:")
print(copool.execute(simpleCalculation))

print("\n2. Divide and Remainder:")
print(copool.execute(divideAndRemainder, 17))


print("\n3. Weighted Sum:")
print(copool.execute(weightedSum, 10, 20, 30, 0.5, 0.3, 0.2))

print("\n4. Stats Calculator:")
print(copool.execute(statsCalculator, 3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5))

print("\n5. String Processing:")
print(copool.execute(processString, "hello,world,lua", ","))

print("\n6. Complex Calculation:")
print(copool.execute(complexCalculation, "sum", 1, 2, 3, 4, 5))
print(copool.execute(complexCalculation, "product", 2, 3, 4))
print(copool.execute(complexCalculation, "unknown", 1, 2, 3))

print("\n7. Simulated Async Operation:")
print(copool.execute(simulateAsyncOperation, 3, "a", "b", "c"))
