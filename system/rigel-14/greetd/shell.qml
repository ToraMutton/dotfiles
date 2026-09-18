import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Greetd
import Quickshell.Io

ShellRoot {
   PanelWindow {
       id: window

       screen: Quickshell.screens[0]

       anchors {
           top: true
           right: true
           bottom: true
           left: true
       }

       color: "transparent"
       focusable: true
       aboveWindows: true
       exclusionMode: ExclusionMode.Ignore

       WlrLayershell.namespace: "rigel-greeter"
       WlrLayershell.layer: WlrLayer.Overlay
       WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

       Shortcut {
           sequence: "Escape"
           enabled: !Greetd.available
           onActivated: Qt.quit()
       }

       Item {
           id: root
           anchors.fill: parent

           property date now: new Date()
           property string pendingSecret: ""
           property bool busy: false
           property string powerAction: ""
           property string statusText: Greetd.available
               ? "ENTER PASSWORD  •  HYPRLAND"
               : "PREVIEW MODE  •  authentication is disconnected"

           function idleStatus() {
               return Greetd.available
                   ? "ENTER PASSWORD  •  HYPRLAND"
                   : "PREVIEW MODE  •  authentication is disconnected"
           }

           function submitLogin() {
               if (busy)
                   return

               powerAction = ""
               powerConfirmTimer.stop()

               if (passwordInput.text.length === 0) {
                   statusText = "Enter your password"
                   passwordInput.forceActiveFocus()
                   return
               }

               if (!Greetd.available) {
                   statusText = "Preview only — no password was transmitted"
                   passwordInput.text = ""
                   return
               }

               busy = true
               pendingSecret = passwordInput.text
               statusText = "AUTHENTICATING…"
               Greetd.createSession("toramutton")
           }

           function requestPower(action) {
               if (busy)
                   return

               if (powerAction !== action) {
                   powerAction = action
                   powerConfirmTimer.restart()
                   statusText = action === "reboot"
                       ? "CLICK RESTART AGAIN WITHIN 5 SECONDS"
                       : "CLICK POWER OFF AGAIN WITHIN 5 SECONDS"
                   return
               }

               if (!Greetd.available) {
                   powerConfirmTimer.stop()
                   powerAction = ""
                   statusText = "Preview only — no power command was executed"
                   return
               }

               powerConfirmTimer.stop()
               powerAction = ""
               pendingSecret = ""
               passwordInput.text = ""
               busy = true
               statusText = action === "reboot"
                   ? "REBOOTING…"
                   : "POWERING OFF…"
               powerProcess.exec(["/usr/bin/systemctl", action])
           }

           Timer {
               id: powerConfirmTimer
               interval: 5000
               repeat: false

               onTriggered: {
                   root.powerAction = ""
                   if (!root.busy)
                       root.statusText = root.idleStatus()
               }
           }

           Process {
               id: powerProcess

               onExited: function(exitCode, exitStatus) {
                   if (exitCode !== 0) {
                       root.busy = false
                       root.powerAction = ""
                       root.statusText = "Power command failed (exit "
                           + exitCode + ")"
                       passwordInput.forceActiveFocus()
                   }
               }
           }

           Connections {
               target: Greetd

               function onAuthMessage(message, error, responseRequired, echoResponse) {
                   if (error && message.length > 0)
                       root.statusText = message

                   if (responseRequired) {
                       const response = root.pendingSecret
                       root.pendingSecret = ""
                       passwordInput.text = ""
                       Greetd.respond(response)
                   } else if (!error && message.length > 0) {
                       root.statusText = message
                   }
               }

               function onAuthFailure(message) {
                   root.pendingSecret = ""
                   root.busy = false
                   passwordInput.text = ""
                   root.statusText = message.length > 0
                       ? message
                       : "Authentication failed — try again"
                   passwordInput.forceActiveFocus()
               }

               function onReadyToLaunch() {
                   root.statusText = "STARTING HYPRLAND…"
                   Greetd.launch(["/usr/bin/start-hyprland"], [], true)
               }

               function onLaunched() {
                   root.pendingSecret = ""
               }

               function onError(message) {
                   root.pendingSecret = ""
                   root.busy = false
                   root.statusText = "greetd error: " + message
                   passwordInput.forceActiveFocus()
               }
           }

           Timer {
               interval: 1000
               running: true
               repeat: true
               onTriggered: root.now = new Date()
           }

           Image {
               id: wallpaper
               anchors.fill: parent
               source: "file:///usr/share/backgrounds/rigel-14/login-background.jpg"
               fillMode: Image.PreserveAspectCrop
               asynchronous: true
               cache: true
               mipmap: true
           }

           Rectangle {
               anchors.fill: parent
               color: "#35000000"
           }

           /* 左上の時計 */
           Item {
               id: clockBlock
               x: Math.max(72, root.width * 0.065)
               y: Math.max(62, root.height * 0.075)
               width: 520
               height: 180

               Text {
                   id: clockText
                   text: Qt.formatDateTime(root.now, "HH:mm")
                   color: "#f8f5ff"
                   font.family: "Hack Nerd Font"
                   font.pixelSize: Math.min(92, root.height * 0.095)
                   font.weight: Font.Light
                   font.letterSpacing: -3
               }

               Text {
                   anchors.top: clockText.bottom
                   anchors.topMargin: 4
                   text: Qt.formatDateTime(root.now, "yyyy.MM.dd  dddd")
                   color: "#b9aec9"
                   font.family: "Noto Sans"
                   font.pixelSize: 18
                   font.letterSpacing: 1.5
               }
           }

           /* 左下のマシン表示 */
           Item {
               x: Math.max(74, root.width * 0.065)
               y: root.height - 130
               width: 420
               height: 70

               Rectangle {
                   width: 42
                   height: 3
                   radius: 2
                   color: "#c084fc"
               }

               Text {
                   anchors.top: parent.top
                   anchors.topMargin: 15
                   text: "rigel-14"
                   color: "#f4edff"
                   font.family: "Hack Nerd Font"
                   font.pixelSize: 21
                   font.weight: Font.DemiBold
                   font.letterSpacing: 4
               }

               Text {
                   anchors.top: parent.top
                   anchors.topMargin: 46
                   text: "ARCH LINUX  •  HYPRLAND"
                   color: "#81758f"
                   font.family: "Hack Nerd Font"
                   font.pixelSize: 11
                   font.letterSpacing: 2
               }
           }

           /* カード後方の斜めアクセント */
           Rectangle {
               id: diagonalAccent
               x: loginCard.x - 24
               y: loginCard.y + 20
               width: loginCard.width
               height: loginCard.height
               radius: 38
               rotation: -4.2
               color: "#221b102c"
               border.width: 1
               border.color: "#665b21b6"
           }

           /* 壁紙の該当領域を取り込んでぼかす */
           ShaderEffectSource {
               id: glassCapture
               sourceItem: wallpaper
               sourceRect: Qt.rect(
                   loginCard.x,
                   loginCard.y,
                   loginCard.width,
                   loginCard.height
               )
               textureSize: Qt.size(loginCard.width, loginCard.height)
               live: true
               hideSource: false
               visible: false
           }

           /* 右側のフロストガラスカード */
           Item {
               id: loginCard

               width: Math.min(470, root.width * 0.34)
               height: Math.min(610, root.height * 0.66)

               x: root.width - width - Math.max(84, root.width * 0.075)
               y: (root.height - height) / 2 + 18

               clip: true

               MultiEffect {
                   anchors.fill: parent
                   source: glassCapture
                   blurEnabled: true
                   blur: 0.78
                   blurMax: 64
                   saturation: -0.25
                   brightness: -0.12
               }

               Rectangle {
                   anchors.fill: parent
                   radius: 34
                   color: "#72100b1d"
                   border.width: 1
                   border.color: "#55ffffff"
               }

               Rectangle {
                   x: 28
                   y: 26
                   width: 70
                   height: 2
                   radius: 1
                   color: "#a855f7"
               }

               /* 閉じる */
               Rectangle {
                   id: closeButton
                   visible: !Greetd.available
                   x: parent.width - 62
                   y: 24
                   width: 38
                   height: 38
                   radius: 19
                   color: closeMouse.containsMouse ? "#30ffffff" : "#14ffffff"
                   border.width: 1
                   border.color: "#28ffffff"

                   Text {
                       anchors.centerIn: parent
                       text: "×"
                       color: "#e9e3ef"
                       font.family: "Noto Sans"
                       font.pixelSize: 23
                       font.weight: Font.Light
                   }

                   MouseArea {
                       id: closeMouse
                       anchors.fill: parent
                       hoverEnabled: true
                       cursorShape: Qt.PointingHandCursor
                       onClicked: Qt.quit()
                   }
               }

               /* アバター */
               Rectangle {
                   id: avatarGlow
                   anchors.horizontalCenter: parent.horizontalCenter
                   y: 58
                   width: 112
                   height: 112
                   radius: 56
                   color: "#301f063f"
                   border.width: 1
                   border.color: "#70d8b4fe"

                   Rectangle {
                       anchors.centerIn: parent
                       width: 94
                       height: 94
                       radius: 47
                       color: "#5f2a0d79"
                       border.width: 1
                       border.color: "#65ffffff"

                       Item {
                           id: avatarViewport
                           anchors.fill: parent
                           anchors.margins: 3

                           Image {
                               id: avatarSource
                               anchors.fill: parent
                               source: "file:///usr/share/pixmaps/rigel-14/avatar.jpeg"
                               fillMode: Image.PreserveAspectCrop
                               sourceSize: Qt.size(256, 256)
                               asynchronous: true
                               cache: true
                               visible: false
                           }

                           Rectangle {
                               id: avatarMask
                               anchors.fill: parent
                               radius: width / 2
                               color: "white"
                               visible: false
                               layer.enabled: true
                           }

                           MultiEffect {
                               anchors.fill: parent
                               source: avatarSource
                               maskEnabled: true
                               maskSource: avatarMask
                               visible: avatarSource.status === Image.Ready
                           }

                           Text {
                               anchors.centerIn: parent
                               visible: avatarSource.status === Image.Error
                               text: "T"
                               color: "#faf7ff"
                               font.family: "Noto Sans"
                               font.pixelSize: 42
                               font.weight: Font.Light
                           }
                       }
                   }
               }

               Text {
                   anchors.horizontalCenter: parent.horizontalCenter
                   y: 188
                   text: "Welcome back"
                   color: "#ffffff"
                   font.family: "Noto Sans"
                   font.pixelSize: 25
                   font.weight: Font.DemiBold
               }

               Text {
                   anchors.horizontalCenter: parent.horizontalCenter
                   y: 226
                   text: "toramutton"
                   color: "#b9aec9"
                   font.family: "Hack Nerd Font"
                   font.pixelSize: 14
                   font.letterSpacing: 1.5
               }

               /* パスワード入力 */
               Rectangle {
                   id: passwordCapsule
                   x: 48
                   y: 286
                   width: parent.width - 96
                   height: 62
                   radius: 31
                   color: passwordInput.activeFocus
                       ? "#621b1328"
                       : "#48100c19"
                   border.width: 1
                   border.color: passwordInput.activeFocus
                       ? "#b8d8b4fe"
                       : "#42ffffff"

                   Text {
                       anchors.left: parent.left
                       anchors.leftMargin: 22
                       anchors.verticalCenter: parent.verticalCenter
                       visible: passwordInput.text.length === 0
                       text: "Password"
                       color: "#81758f"
                       font.family: "Noto Sans"
                       font.pixelSize: 15
                   }

                   TextInput {
                       id: passwordInput
                       anchors.left: parent.left
                       anchors.leftMargin: 22
                       anchors.right: loginButton.left
                       anchors.rightMargin: 10
                       anchors.verticalCenter: parent.verticalCenter

                       color: "#ffffff"
                       selectionColor: "#805b21b6"
                       selectedTextColor: "#ffffff"
                       font.family: "Noto Sans"
                       font.pixelSize: 17

                       echoMode: TextInput.Password
                       passwordCharacter: "•"
                       passwordMaskDelay: 450
                       selectByMouse: true
                       clip: true
                       enabled: !root.busy

                       Keys.onReturnPressed: root.submitLogin()

                       Component.onCompleted: forceActiveFocus()
                   }

                   Rectangle {
                       id: loginButton
                       anchors.right: parent.right
                       anchors.rightMargin: 5
                       anchors.verticalCenter: parent.verticalCenter

                       width: 52
                       height: 52
                       radius: 26

                       color: loginMouse.pressed
                           ? "#7e22ce"
                           : loginMouse.containsMouse
                               ? "#a855f7"
                               : "#8b5cf6"
                       opacity: root.busy ? 0.55 : 1.0

                       Text {
                           anchors.centerIn: parent
                           text: root.busy ? "…" : "→"
                           color: "#ffffff"
                           font.family: "Noto Sans"
                           font.pixelSize: 25
                           font.weight: Font.Medium
                       }

                       MouseArea {
                           id: loginMouse
                           anchors.fill: parent
                           hoverEnabled: true
                           enabled: !root.busy
                           cursorShape: Qt.PointingHandCursor
                           onClicked: root.submitLogin()
                       }
                   }
               }

               Text {
                   x: 50
                   y: 366
                   width: parent.width - 100
                   text: root.statusText
                   color: "#92869e"
                   font.family: "Hack Nerd Font"
                   font.pixelSize: 10
                   font.letterSpacing: 0.5
                   horizontalAlignment: Text.AlignHCenter
                   wrapMode: Text.WordWrap
               }

               Rectangle {
                   x: 48
                   y: parent.height - 118
                   width: parent.width - 96
                   height: 1
                   color: "#22ffffff"
               }

               /* 5秒以内の二度押しで再起動 */
               Rectangle {
                   id: rebootButton
                   x: parent.width / 2 - 66
                   y: parent.height - 94
                   width: 52
                   height: 52
                   radius: 26
                   color: root.powerAction === "reboot"
                       ? "#358b5cf6"
                       : rebootMouse.containsMouse
                           ? "#28ffffff"
                           : "#12ffffff"
                   border.width: 1
                   border.color: root.powerAction === "reboot"
                       ? "#90c084fc"
                       : "#30ffffff"

                   Text {
                       anchors.centerIn: parent
                       text: "↻"
                       color: "#d7cfdf"
                       font.family: "Noto Sans"
                       font.pixelSize: 23
                   }

                   MouseArea {
                       id: rebootMouse
                       anchors.fill: parent
                       hoverEnabled: true
                       enabled: !root.busy
                       cursorShape: Qt.PointingHandCursor
                       onClicked: root.requestPower("reboot")
                   }
               }

               /* 5秒以内の二度押しで電源OFF */
               Rectangle {
                   id: powerButton
                   x: parent.width / 2 + 14
                   y: parent.height - 94
                   width: 52
                   height: 52
                   radius: 26
                   color: root.powerAction === "poweroff"
                       ? "#50ef4444"
                       : powerMouse.containsMouse
                           ? "#35ef4444"
                           : "#12ffffff"
                   border.width: 1
                   border.color: root.powerAction === "poweroff"
                       ? "#a0f87171"
                       : powerMouse.containsMouse
                           ? "#70f87171"
                           : "#30ffffff"

                   Text {
                       anchors.centerIn: parent
                       text: "⏻"
                       color: powerMouse.containsMouse
                           ? "#fecaca"
                           : "#d7cfdf"
                       font.family: "Noto Sans"
                       font.pixelSize: 21
                   }

                   MouseArea {
                       id: powerMouse
                       anchors.fill: parent
                       hoverEnabled: true
                       enabled: !root.busy
                       cursorShape: Qt.PointingHandCursor
                       onClicked: root.requestPower("poweroff")
                   }
               }
           }

           Text {
               visible: !Greetd.available
               anchors.right: parent.right
               anchors.rightMargin: 24
               anchors.bottom: parent.bottom
               anchors.bottomMargin: 18
               text: "PREVIEW  •  ESC TO CLOSE"
               color: "#665c6e"
               font.family: "Hack Nerd Font"
               font.pixelSize: 10
               font.letterSpacing: 1.5
           }
       }
   }
}
