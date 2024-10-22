
local micMute={}
micMute.__index = obj

-- Metadata
micMute.name = "MicMute"
micMute.version = "1.0"
micMute.author = "abrayko <abrayko@github.com>"
micMute.license = "MIT - https://opensource.org/licenses/MIT"

-- Clear the alert if exists to avoid notifications stacking
function micMute.clearMuteAlert()
  if micMute.muteAlertId then
    hs.alert.closeSpecific(micMute.muteAlertId)
  end
end

-- Hold the hotkey for Push To Talk
function micMute.pushToTalk()
  micMute.holdingToTalk = true
  local audio = hs.audiodevice.defaultInputDevice()
  local muted = audio:inputMuted()
  if muted then
    micMute.clearMuteAlert()
    micMute.muteAlertId = hs.alert.showWithImage("Microphone on", micMute.iconMicOn:setSize({h=32, w=32}))
    audio:setInputMuted(false)
  end
end

-- Toggles the default microphone's mute state on hotkey release
-- or performs PTT when holding down the hotkey
function micMute.toggleMuteOrPTT(isAlert)
  local audio = hs.audiodevice.defaultInputDevice()
  local muted = audio:inputMuted()
  local muting = not muted
  if micMute.holdingToTalk then
    micMute.holdingToTalk = false
    audio:setInputMuted(true)
    muting = true
  else
    audio:setInputMuted(muting)
  end
  micMute.clearMuteAlert()
	--speech = hs.speech.new()
  if muting then
    if isAlert then
      micMute.muteAlertId = hs.alert.showWithImage("Microphone muted", micMute.iconMicRedOff:setSize({h=32, w=32}))
    end
    audio:setInputVolume(0)
		---speech:speak("mic off")
  else
    if isAlert then
      micMute.muteAlertId = hs.alert.showWithImage("Microphone on", micMute.iconMicOn:setSize({h=32, w=32}))
    end
    audio:setInputVolume(100)
		---speech:speak("mic on")
  end
end

function micMute.toggleBykeys()
  micMute.checkAndreinitWatchAudio()
  micMute.toggleMuteOrPTT(true)
end

function micMute.watcherMenuClick()
  micMute.checkAndreinitWatchAudio()
  micMute.toggleMuteOrPTT(false)
end

function micMute.setIcon(aud)
  micMute.log:d("audio device: " .. aud:uid())
  local muted = aud:inputMuted()
  if muted then 
    micMute.micmenu:setIcon(micMute.iconMicOff:setSize({h=20, w=20}), false)
  else 
    micMute.micmenu:setIcon(micMute.iconMicOn:setSize({h=20, w=20}), false)
  end
end 


-- watch audiodevice events
function micMute.watcherAudio(uid, event, scope, el)
  micMute.log.d("audio device: " .. uid)
  micMute.log.d("event: " .. event)
  if event == "gone" or event == "mute" then
    local aud = hs.audiodevice.defaultInputDevice()
    if aud:uid() == uid then
      -- замьютили или переключились на устройство по умолчанию
      micMute.setIcon(aud)
    else
      -- если устройство не по умолчанию, то прекращаем его слушать
      if aud:watcherIsRunning() then
        micMute.watcherStop()
        micMute.watcherCallback(nil)
      end
    end
  end
end

-- Init
function micMute.init()
  hs.console.clearConsole()
  micMute.log = hs.logger.new("MicMute", "debug")
  micMute.log.d("init ")

  micMute.holdingToTalk = false
  micMute.muteAlertId = nil

  micMute.micmenu = hs.menubar.new(true, "MicMute")
  micMute.iconMicOn = hs.image.imageFromPath("./icons/micOn.svg")
  micMute.iconMicOff = hs.image.imageFromPath("./icons/micOffCircle.svg")
  micMute.iconMicRedOff = hs.image.imageFromPath("./icons/MicSlashCircleOffRed.svg")
  micMute.micmenu:setClickCallback(micMute.watcherMenuClick)
  micMute.setIcon(hs.audiodevice.defaultInputDevice())

  micMute.initWatchAudio()
end

function micMute.initWatchAudio()
  -- watch system scope device change
  if not hs.audiodevice.watcher.isRunning() then
    micMute.log.d("init system scope audiodevice watcher")
    hs.audiodevice.watcher.setCallback(function(event) 
        micMute.log.d(event)
        if string.find(event, "dIn ") then
          micMute.log.d("reset icon")
          micMute.checkAndreinitWatchAudio()
          local aud = hs.audiodevice.defaultInputDevice()
          micMute.setIcon(aud)
        end
      end
    )
    hs.audiodevice.watcher.start()
  end

  --  watch system sleep/wake event
  micMute.sysWatcher = hs.caffeinate.watcher.new(
    function (event)
      micMute.log.d(event)
      if event ==	hs.caffeinate.watcher.systemDidWake then
        micMute.checkAndreinitWatchAudio()
      end
    end 
  )
  micMute.sysWatcher:start()
end

function micMute.checkAndreinitWatchAudio()
  local aud = hs.audiodevice.defaultInputDevice()
  if not aud:watcherIsRunning() then
    aud:watcherCallback(micMute.watcherAudio)
    aud:watcherStart()
  end
end

micMute.init()


hs.hotkey.bind({"ctrl", "alt"}, "m", nil, micMute.toggleBykeys, micMute.pushToTalk)


hs.console.clearConsole()
micMute.log.setLogLevel("warning")

