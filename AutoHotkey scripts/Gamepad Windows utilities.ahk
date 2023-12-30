#include XInput.ahk 

XInput_GetStateEx(user_index)
{
    global

    if state := XInput_GetState(user_index) {
        return,
        (Join
            {
                BUTTON:
                {
                    DPAD_UP:        (state.wButtons & XINPUT_GAMEPAD_DPAD_UP) != 0,
                    DPAD_DOWN:      (state.wButtons & XINPUT_GAMEPAD_DPAD_DOWN) != 0,
                    DPAD_LEFT:      (state.wButtons & XINPUT_GAMEPAD_DPAD_LEFT) != 0,
                    DPAD_RIGHT:     (state.wButtons & XINPUT_GAMEPAD_DPAD_RIGHT) != 0,
                    START:          (state.wButtons & XINPUT_GAMEPAD_START) != 0,
                    BACK:           (state.wButtons & XINPUT_GAMEPAD_BACK) != 0,
                    LEFT_THUMB:     (state.wButtons & XINPUT_GAMEPAD_LEFT_THUMB) != 0,
                    RIGHT_THUMB:    (state.wButtons & XINPUT_GAMEPAD_RIGHT_THUMB) != 0,
                    LEFT_SHOULDER:  (state.wButtons & XINPUT_GAMEPAD_LEFT_SHOULDER) != 0,
                    RIGHT_SHOULDER: (state.wButtons & XINPUT_GAMEPAD_RIGHT_SHOULDER) != 0,
                    GUIDE:          (state.wButtons & XINPUT_GAMEPAD_GUIDE) != 0,
                    A:              (state.wButtons & XINPUT_GAMEPAD_A) != 0,
                    B:              (state.wButtons & XINPUT_GAMEPAD_B) != 0,
                    X:              (state.wButtons & XINPUT_GAMEPAD_X) != 0,
                    Y:              (state.wButtons & XINPUT_GAMEPAD_Y) != 0
                },
                TRIGGER:
                {
                    LEFT: state.bLeftTrigger,
                    RIGHT: state.bRightTrigger
                },
                THUMB:
                {
                    LEFT:
                    {
                        X: state.sThumbLX,
                        Y: state.sThumbLY
                    },
                    RIGHT:
                    {
                        X: state.sThumbRX,
                        Y: state.sThumbRY
                    }
                }
            }
        )
    }

    return 0
}

ACTION := 0
CLICKING := false
SWITCHING := false

XInput_Init()
Loop {
    Loop, 4 {
        if gamepad := XInput_GetStateEx(A_INDEX-1) {
            right_thumb_x := Abs(gamepad.thumb.right.x) > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE? gamepad.thumb.right.x : 0
            right_thumb_y := Abs(gamepad.thumb.right.y) > XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE? gamepad.thumb.right.y : 0
            right_thumb_active := right_thumb_x or right_thumb_y

            trigger_left  := gamepad.trigger.left  > 128
            trigger_right := gamepad.trigger.right > 128

            if gamepad.button.back and (gamepad.button.start or (ACTION and ACTION != "switch")) {
                switch ACTION {
                    default:
                        if trigger_left and trigger_right {
                            SoundBeep
                            Send, {media_play_pause}
                            ACTION := "media"
                        } else if trigger_right and gamepad.trigger.left < XINPUT_GAMEPAD_TRIGGER_THRESHOLD {
                            Send, {volume_up down}
                        } else if trigger_left and gamepad.trigger.right < XINPUT_GAMEPAD_TRIGGER_THRESHOLD {
                            Send, {volume_down down}
                        }

                        if gamepad.button.right_shoulder {
                            SoundBeep
                            Send, {alt down}{tab}
                            ACTION := "switch"
                        }

                        if gamepad.button.left_shoulder {
                            SoundBeep
                            Send, !{F4}
                            ACTION := "closing"
                        }

                        if gamepad.button.x {
                            SoundBeep
                            Send, {Enter}
                        }

                        if right_thumb_active or gamepad.button.right_thumb {
                            SoundBeep
                            ACTION := "Mouse"
                        }
                    case "switch":
                        if gamepad.button.right_shoulder {
                            if !SWITCHING
                                Send, {tab}
                            SWITCHING := true
                        } else
                            SWITCHING := false
                    case "closing":
                        if !gamepad.button.b
                            ACTION := 0
                    case "media":
                        if !trigger_left or !trigger_right
                            ACTION := 0
                    case "mouse":
                        if !CLICKING {
                            if gamepad.button.right_shoulder
                                Click, down
                            if gamepad.button.left_shoulder
                                Click, down right
                        } else {
                            if (CLICKING = "left" and !gamepad.button.right_shoulder)
                                Click, up
                            else if (CLICKING = "right" and !gamepad.button.left_shoulder)
                                Click, up right
                        }
                        CLICKING := gamepad.button.right_shoulder? "left" : gamepad.button.left_shoulder? "right" : false

                        if trigger_right 
                            Click WD
                        if trigger_left
                            Click WU

                        speed_x := (Abs(right_thumb_x) = 0? 0
                            : Abs(right_thumb_x) < 15000? 3
                            : 10 + (Abs(right_thumb_x) - 15000) / 710.72)
                        speed_y := (Abs(right_thumb_y) = 0? 0
                            : Abs(right_thumb_y) < 15000? 3
                            : 10 + (Abs(right_thumb_y) + 15000) / 1263.5022222222)

                        MouseMove, speed_x * (right_thumb_x > 0? 1 : -1), -speed_y * (right_thumb_y > 0? 1 : -1), 0, R
                }
            } else if ACTION {
                switch ACTION {
                    case "switch":
                        Send, {alt up}
                }
                ACTION := 0
                Tooltip
            }
        }
    }
    Sleep, (ACTION = "mouse"? -1 : 50)
}
