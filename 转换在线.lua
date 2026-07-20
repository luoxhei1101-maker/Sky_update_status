function GN(a,b)
    local c = gg.getValues({{['address'] = a + b, ['flags'] = 32}})[1]['value']
    return c 
end 

function GL(num1, flag1, pianyi1, num2, flag2, pianyi2)
    gg.setVisible(false)
    gg.clearResults()
    gg.searchNumber(tostring(num1), flag1)
    local resCount = gg.getResultCount() 
    if resCount ~= 0 then 
        local result = gg.getResults(resCount)
        local tmp = {}
        for i, v in ipairs(result) do 
            tmp[#tmp + 1] = {address = v.address + pianyi1, flags = flag2} 
        end 
        tmp = gg.getValues(tmp) 
        for i, v in ipairs(tmp) do 
            if v.value == num2 then 
                tmp = tmp[i].address + pianyi2 
                return tmp 
            end 
        end 
    end 
    return 0 
end

HA = {}
HA[1] = {address = GL("1023969417", 4, -0x8, 1, 4, 0x18 + 8) + 0xA60, flags = 4}

Func = {
    Landing = function()
        local b = {}
        for i = 1, 32 do
            b[i] = {address = HA[1].address - 0x2C + i + 1, flags = 1, value = 0}
        end
        b[#b + 1] = {address = gg.getValues({{address = HA[1].address, flags = 32}})[1].value + 0xC, flags = 4, value = 0}
        b[#b + 1] = {address = HA[1].address - 8, flags = 32, value = 1}
        gg.setValues(b)
    end,
    --https还是http全取决于你配不配置证书，配不配置都无所谓，不过反代那里必须配置，因为游戏它必须https
    UpdateStatus = function()
        local response = gg.makeRequest(
            "https://你的在线提交域名/update_status",
            {
                ["Authorization"] = "你的token",
                ["Content-Type"] = "application/json"
            },
            '{"update_status":"Working"}',  -- 数据参数
            "POST"  -- 方法参数
        )
        return response and response.code == 200
    end,
    
    CheckTask = function()
        local response = gg.makeRequest(
            "https://你的域名/get_task_status",
            {
                ["Authorization"] = "你的token",
                ["Content-Type"] = "application/json"
            },
            "{}",  
            "POST"  
        )
        if response and response.code == 200 then
            if response.content:find('{"status":"NewTask"}') then
                if Func.UpdateStatus() then
                    gg.toast("状态更新成功")
                    return true
                else
                    gg.toast("状态更新失败")
                    return false
                end
            end
        end
        return false
    end
}

function Monitor()
    while true do
        if Func.CheckTask() then
            gg.toast("执行重新登录...")
            Func.Landing()
        end
        gg.sleep(2000)
    end
end

function Main()
    menu = gg.choice({
        "🌟 立即重新登录",
        "🔄 启动后台监控",
        "❌ 退出脚本"
    }, nil, "光遇自动化工具 v2.0")
    
    if menu == 1 then
        Func.Landing()
        gg.toast("重新登录操作已执行")
    elseif menu == 2 then
        gg.toast("后台监控已启动")
        Monitor()
    elseif menu == 3 then
        os.exit()
    end
end

gg.setVisible(false)
gg.toast("脚本加载成功")
while true do
    if gg.isVisible(true) then
        gg.setVisible(false)
        Main()
    end
    gg.sleep(100)
end