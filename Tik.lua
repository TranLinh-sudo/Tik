--[[
    ============================================================
    SPY TOOL - WEBHOOK.SITE VERSION (FINAL)
    Target: Blox Fruits (CommF_)
    Status: Ready to run
    ============================================================
]]

-- CẤU HÌNH (Đã điền link của bạn)
getgenv().API_URL = "https://webhook.site/2fa2856c-84aa-4b5d-889d-1247e7a98988"

local Config = {
    MinBatch = 5,        -- Gom đủ 5 dòng code mới gửi (để giảm lag)
    TimeOut = 4,         -- Hoặc cứ 4 giây gửi 1 lần
    RemoteName = "CommF_" -- Chỉ bắt Remote này
}

-- KHỞI TẠO DỊCH VỤ
local HttpService = game:GetService("HttpService")
local RequestFunc = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

if not RequestFunc then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Lỗi Executor";
        Text = "Executor không hỗ trợ gửi HTTP Request!";
        Duration = 5;
    })
    return
end

local LogQueue = {}
local LastSendTime = tick()

-- HÀM GỬI DỮ LIỆU (DISPATCH)
local function DispatchLogs()
    if #LogQueue == 0 then return end

    -- Gom toàn bộ hàng đợi thành 1 văn bản
    local contentToSend = table.concat(LogQueue, "\n")
    
    -- Reset hàng đợi ngay lập tức để đón dữ liệu mới
    LogQueue = {}
    LastSendTime = tick()

    -- Gửi Request
    pcall(function()
        RequestFunc({
            Url = getgenv().API_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "text/plain" -- Gửi dạng văn bản thường cho dễ đọc
            },
            Body = contentToSend
        })
    end)
end

-- HÀM XỬ LÝ THAM SỐ (FORMATTER)
local function CleanArg(v)
    if typeof(v) == "string" then
        return '"' .. v .. '"'
    elseif typeof(v) == "Vector3" then
        return string.format("Vector3.new(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z)
    elseif typeof(v) == "CFrame" then
        return string.format("CFrame.new(%s)", tostring(v.Position))
    elseif typeof(v) == "table" then
        return "{...}" -- Rút gọn table để code không quá dài
    elseif typeof(v) == "Instance" then
        return "game." .. v:GetFullName()
    else
        return tostring(v)
    end
end

-- CORE: HOOK METAMETHOD
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    
    -- Chỉ bắt FireServer hoặc InvokeServer của CommF_
    if (method == "FireServer" or method == "InvokeServer") and self.Name == Config.RemoteName then
        local args = {...}
        local argsStr = ""
        
        -- Biến đổi tham số thành chuỗi code
        for i, v in ipairs(args) do
            argsStr = argsStr .. CleanArg(v)
            if i < #args then argsStr = argsStr .. ", " end
        end

        -- Tạo dòng code hoàn chỉnh
        local timestamp = os.date("%H:%M:%S")
        local finalCode = string.format("[%s] game.ReplicatedStorage.Remotes['CommF_']:%s(%s)", timestamp, method, argsStr)
        
        -- Đưa vào hàng đợi
        table.insert(LogQueue, finalCode)

        -- Nếu hàng đợi đầy thì gửi ngay
        if #LogQueue >= Config.MinBatch then
            DispatchLogs()
        end
    end

    return oldNamecall(self, ...)
end))

-- VÒNG LẶP GỬI ĐỊNH KỲ (FALLBACK)
-- Đảm bảo dù ít dữ liệu vẫn gửi sau mỗi 4 giây
task.spawn(function()
    while task.wait(1) do
        if tick() - LastSendTime >= Config.TimeOut then
            DispatchLogs()
        end
    end
end)

-- THÔNG BÁO ĐÃ BẬT
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "SPY TOOL ACTIVE";
    Text = "Đã kết nối Webhook.site!";
    Duration = 5;
})
