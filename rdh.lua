local disks = {}
local periphPath = {}
local path
for k, periph in pairs(peripheral.getNames()) do
    if peripheral.getType(periph) == "drive" then
        if peripheral.call(periph, "isDiskPresent") and peripheral.call(periph, "hasData") then
            path = peripheral.call(periph, "getMountPath")
            periphPath[periph] = path
            disks[path] = {}
        end
    end
end
local timer = os.startTimer(5)
local dirReader = require("AllFiles")
local IDs = {}
local debugMode = false
local function read(name)
    log(name)
    local file = fs.open(name, "rb")
    local text = textutils.serialise(file.readAll())
    file.close()
    return text
end
local function save(name, content)
    log("writing")
    log(name)
    log(content)
    local file = fs.open(name, "wb")
    file.write(textutils.unserialise(content))
    file.flush()
    file.close()
end
local logFile = "rdh.log"
file = fs.open(logFile, "w")
file.write("")
file.flush()
file.close()
function log(text)
    if debugMode then
        text = textutils.serialise(text)
        print(text)
        local file = fs.open(logFile, "a")
        file.write(text.."\n")
        file.flush()
        file.close()
    end
end
local function send(msg)
    for k, ID in pairs(IDs) do
        log("rednet-out")
        log(msg)
        rednet.send(ID, msg, "rdh")
    end
end
local function connect(id)
    table.insert(IDs, id)
    rednet.send(id, "connect", "rdh")
    local ID, msg, prot
    while id ~= ID or prot ~= "rdh" do
        rednet.send(id, "connect", "rdh")
        ID, msg, prot = rednet.receive()
        log("rednet-in")
        log(msg)
    end
    disks = textutils.unserialise(msg)
    for Disk, files in pairs(disks) do
        fs.makeDir(Disk)
        for file, content in pairs(files) do
            if string.sub(content, 1, 5) == "file/" then
                save(file, string.sub(content, 6))
            else
                fs.makeDir(file)
            end
        end
    end
end
local function update(event)
    if event[1] == "rednet_message" and event[4] == "rdh" then
        log("rednet-in")
        log(event[3])
        if event[3] == "connect" then
            hasID = false
            cont = 1
            while cont <= table.getn(IDs) and not hasID do
                hasID = IDs[cont] == event[2]
                cont = cont + 1
            end
            if not hasID then
                table.insert(IDs, event[2])
            end
            rednet.send(event[2], textutils.serialise(disks), "rdh")
            log("rednet-out")
            log(disks)
        else
            if event[3] == nil then
                rednet.send(event[2], nil, "rdh")
            else
                if event[3][1] == "disk" then
                    disks[event[3][2]] = {}
                    fs.makeDir(event[3][2])
                    log("mkdir "..event[3][2])
                else
                    if event[3][1] == "eject" then
                        disks[event[3][2]] = nil
                        fs.delete(event[3][2])
                        log("delete "..event[3][2])
                    else
                        if event[3][1] == "file" then
                            disks[event[3][2]][event[3][3]] = "file/"..event[3][4]
                            save(event[3][3], event[3][4])
                        else
                            if event[3][1] == "dire" then
                                disks[event[3][2]][event[3][3]] = "dire"
                                fs.makeDir(event[3][3])
                                log("mkdir "..event[3][3])
                            else
                                if event[3][1] == "delete" then
                                    disks[event[3][2]][event[3][3]] = nil
                                    fs.delete(event[3][3])
                                    log("delete "..event[3][3])
                                end
                            end
                        end     
                    end
                end
            end
        end
    else
        if event[1] == "disk_eject" then
            path = periphPath[event[2]]
            disks[path] = nil
            send({"eject", path})
        else
            if event[1] == "disk" then
                path = peripheral.call(event[2], "getMountPath")
                periphPath[event[2]] = path
                disks[path] = {}
                send({"disk", path})
            else
                if event[1] == "timer" then
                    if event[2] == timer then
                        log("file check")
                        log(disks)
                        for path, v in pairs(disks) do
                            files = dirReader(path)
                            log(files)
                            for k, file in pairs(files) do
                                file = path.."/"..file
                                if disks[path][file] == nil then
                                    if fs.isDir(file) then
                                        disks[path][file]  = "dire"
                                        send({"dire", path, file})
                                    else
                                        content = read(file)
                                        disks[path][file] = "file/"..content
                                        send({"file", path, file, content})
                                    end
                                else
                                    if not fs.isDir(file) then
                                        content = read(file)
                                        if disks[path][file] ~= "file/"..content then
                                            disks[path][file] = "file/"..content
                                            send({"file", path, file, content})
                                        end
                                    end
                                end
                            end
                        end
                        for Disk, files in pairs(disks) do
                            for file, content in pairs(files) do
                                if not fs.exists(file) then
                                    disks[Disk][file] = nil
                                    send({"delete", Disk, file})
                                end
                            end
                        end
                        timer = os.startTimer(5)
                    end
                end
            end
        end
    end
end
function setDebugMode(deb)
    debugMode = deb
end
return {
    update = update,
    setDebugMode = setDebugMode,
    connect = connect
}
