
muteAlertId = nil

-- Clear the alert if exists to avoid notifications stacking
local function clearMuteAlert()
  if muteAlertId then
    hs.alert.closeSpecific(muteAlertId)
  end
end

-- Hold the hotkey for Push To Talk
local holdingToTalk = false
local function pushToTalk()
  holdingToTalk = true
  local audio = hs.audiodevice.defaultInputDevice()
  local muted = audio:inputMuted()
  if muted then
    clearMuteAlert()
    muteAlertId = hs.alert.showWithImage("Microphone on", iconMicOn:setSize({h=32, w=32}))
    audio:setInputMuted(false)
  end
end

-- Toggles the default microphone's mute state on hotkey release
-- or performs PTT when holding down the hotkey
local function toggleMuteOrPTT(isAlert)
  local audio = hs.audiodevice.defaultInputDevice()
  local muted = audio:inputMuted()
  local muting = not muted
  if holdingToTalk then
    holdingToTalk = false
    audio:setInputMuted(true)
    muting = true
  else
    audio:setInputMuted(muting)
  end
  clearMuteAlert()
	--speech = hs.speech.new()
  if muting then
    if isAlert then
      muteAlertId = hs.alert.showWithImage("Microphone muted", iconMicRedOff:setSize({h=32, w=32}))
    end
    audio:setInputVolume(0)
		---speech:speak("mic off")
  else
    if isAlert then
      muteAlertId = hs.alert.showWithImage("Microphone on", iconMicOn:setSize({h=32, w=32}))
    end
    audio:setInputVolume(100)
		---speech:speak("mic on")
  end
end

local function toggleBykeys()
  checkAndreinitWatchAudio()
  toggleMuteOrPTT(true)
end

local function watcherMenuClick()
  checkAndreinitWatchAudio()
  toggleMuteOrPTT(false)
end

local function setIcon(aud)
  --log:d("audio device: " .. aud:uid())
  local muted = aud:inputMuted()
  if muted then 
    micmenu:setIcon(iconMicOff:setSize({h=20, w=20}), false)
  else 
    micmenu:setIcon(iconMicOn:setSize({h=20, w=20}), false)
  end
end 


-- watch audiodevice events
local function watcherAudio(uid, event, scope, el)
  log.d("audio device: " .. uid)
  log.d("event: " .. event)
  if event == "gone" or event == "mute" then
    local aud = hs.audiodevice.defaultInputDevice()
    if aud:uid() == uid then
      -- замьютили или переключились на устройство по умолчанию
      setIcon(aud)
    else
      -- если устройство не по умолчанию, то прекращаем его слушать
      if aud:watcherIsRunning() then
        aud:watcherStop()
      end
    end
  end
end

-- Init
hs.console.clearConsole()
log = hs.logger.new("micmute", "debug")

micmenu = hs.menubar.new(true, "MicMute")
iconMicOn = hs.image.imageFromPath("./icons/micOn.svg")
iconMicOff = hs.image.imageFromPath("./icons/micOffCircle.svg")
iconMicRedOff = hs.image.imageFromPath("./icons/MicSlashCircleOffRed.svg")
micmenu:setClickCallback(watcherMenuClick)

local audio = hs.audiodevice.defaultInputDevice()
setIcon(audio)


--devs = {}
function initWatchAudio()
  -- watch device event
  --log.d("init audiodevice watchers")
  --for i,dev in ipairs(hs.audiodevice.allInputDevices()) do
  --  if dev.watcherCallback ~= nil then
  --     log.df("Setting up watcher for audio device %s (UID %s)", dev:name(), dev:uid())
  --     devs[dev:uid()]=dev:watcherCallback(watcherAudio)
  --     devs[dev:uid()]:watcherStart()
  --  else
  --     log.w("Your version of Hammerspoon does not support audio device watchers - please upgrade")
  --  end
  --end
  
  -- watch system scope device change
  if not hs.audiodevice.watcher.isRunning() then
    log.d("init system scope audiodevice watcher")
    hs.audiodevice.watcher.setCallback(function(event) 
        log.d(event)
        if string.find(event, "dIn ") then
          log.d("reset icon")
          local aud = hs.audiodevice.defaultInputDevice()
          if not aud:watcherIsRunning() then
            aud:watcherCallback(watcherAudio)
            aud:watcherStart()
          end
          setIcon(aud)
        --elseif string.find(event, "dev#") then
        --  log.d("reset watch list")
        --  stopAndInitWatchAudio()
        end
      end
    )
    hs.audiodevice.watcher.start()
  end
end

--function stopAndInitWatchAudio()
--  -- останавливаем всех
--  for i,v in ipairs(devs) do
--    if v ~= nil then
--      v:watcherStop()
--    end
--  end
--  devs = {}
--  initWatchAudio()
--end

function checkAndreinitWatchAudio()
  --if not next(devs) then
  --  -- если список watcher'ов пуст, то инициализируем заново
  --  devs = {}
  --  initWatchAudio()
  --else
  --  needInit = false
  --  -- проверяем, есть ли хоть один остановленный whatcher
  --  for i,v in ipairs(devs) do
  --    if v ~= nill and not v:watcherIsRunning() then
  --      needInit = true
  --      break
  --    end
  --  end
  --  if needInit then
  --    stopAndInitWatchAudio()
  --    --aud = hs.audiodevice.defaultInputDevice()
  --    --setIcon(aud)
  --  end
  --end
  local aud = hs.audiodevice.defaultInputDevice()
  if not aud:watcherIsRunning() then
    aud:watcherCallback(watcherAudio)
    aud:watcherStart()
  end
end

--  watch system sleep/wake event
sysWatcher = hs.caffeinate.watcher.new(
  function (event)
    log.d(event)
    if event ==	hs.caffeinate.watcher.systemDidWake then
      checkAndreinitWatchAudio()
    end
  end 
)
sysWatcher:start()


--hs.microphoneState(true)
initWatchAudio()

hs.hotkey.bind({"ctrl", "alt"}, "m", nil, toggleBykeys, pushToTalk)
log.setLogLevel("warning")



hs.console.clearConsole()
log = hs.logger.new("micmute", "debug")



--[[
local function watcherUrlMenuClick()
  hs.urlevent.openURL("trueconf:///c/0031213894212@s3.trueconf.rt.ru#vcs&h=s3.trueconf.rt.ru")
end
urlmenu = hs.menubar.new(true, "UrlMenu")
iconUrl = hs.image.imageFromPath("./icons/person conf.svg")
urlmenu:setClickCallback(watcherUrlMenuClick)
urlmenu:setIcon(iconUrl:setSize({h=20, w=20}), false)
]]