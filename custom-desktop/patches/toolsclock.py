#!/usr/bin/env python3
"""The Timers card shows the running timer's remaining time, with pause and stop.

Usage: toolsclock.py <IrisTools.qml> <output>

Ryoku's Timers card (what the Timers bubble opens) only has the start dials.
This adds a row above them while a countdown, Focus session or stopwatch runs,
matching the Island's own timer row.
"""
import sys

src, out = sys.argv[1], sys.argv[2]
s = open(src).read()

ROW = '''    // Custom (toolsclock.py): the running timer, with pause and stop.
    readonly property string runKind: TimerService.pomodoroRunning ? "pomodoro"
        : TimerService.countdownRunning ? "countdown"
        : TimerService.stopwatchRunning ? "stopwatch" : ""
    readonly property bool runPaused: root.runKind === "pomodoro" ? TimerService.pomodoroPaused
        : root.runKind === "countdown" ? TimerService.countdownPaused : TimerService.stopwatchPaused
    readonly property int runSeconds: root.runKind === "pomodoro" ? TimerService.pomodoroSecondsLeft
        : root.runKind === "countdown" ? TimerService.countdownSecondsLeft
        : Math.floor(TimerService.stopwatchTime / 100)
    function runClock(total: real): string {
        const s = Math.max(0, Math.floor(total))
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const pad = n => n < 10 ? "0" + n : String(n)
        return h > 0 ? h + ":" + pad(m) + ":" + pad(s % 60) : m + ":" + pad(s % 60)
    }
    component RunButton: IrisButton {
        id: runButton
        property string glyph: ""
        property color glyphColor: IrisStyle.text
        implicitWidth: Math.round(38 * root.d)
        implicitHeight: implicitWidth
        buttonRadius: height / 2
        buttonRadiusPressed: height / 2
        MaterialSymbol {
            anchors.centerIn: parent
            text: runButton.glyph
            iconSize: 20 * root.d
            color: runButton.glyphColor
        }
    }
    RowLayout {
        visible: root.runKind.length > 0
        Layout.fillWidth: true
        spacing: 8 * root.d
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            IrisText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.runKind === "pomodoro" ? (TimerService.pomodoroLongBreak ? Translation.tr("Long break")
                        : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"))
                    : root.runKind === "countdown" ? Translation.tr("Timer") : Translation.tr("Stopwatch")
                font.weight: IrisStyle.weight(Font.DemiBold)
            }
            IrisText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.runPaused ? Translation.tr("Paused")
                    : root.runKind === "stopwatch" ? Translation.tr("Elapsed") : Translation.tr("Remaining")
                role: IrisText.Meta
            }
        }
        IrisNumber {
            text: root.runClock(root.runSeconds)
            countDown: root.runKind !== "stopwatch"
            color: root.runPaused ? IrisStyle.subtext : IrisStyle.secondaryAccent
            pixelSize: 28 * IrisStyle.typeScale
            weight: Font.Bold
            letterSpacing: -1
        }
        RunButton {
            glyph: root.runPaused ? "play_arrow" : "pause"
            colBackground: IrisStyle.tintFill(IrisStyle.secondaryAccent)
            colBackgroundHover: IrisStyle.tintFillHover(IrisStyle.secondaryAccent)
            glyphColor: IrisStyle.secondaryAccent
            Accessible.name: root.runPaused ? Translation.tr("Resume") : Translation.tr("Pause")
            onClicked: {
                if (root.runKind === "pomodoro") TimerService.togglePomodoro()
                else if (root.runKind === "countdown") TimerService.toggleCountdown()
                else TimerService.toggleStopwatch()
            }
        }
        RunButton {
            glyph: "close"
            colBackground: IrisStyle.fill
            colBackgroundHover: IrisStyle.fillHover
            Accessible.name: Translation.tr("Stop timer")
            onClicked: {
                if (root.runKind === "pomodoro") TimerService.stopPomodoro()
                else if (root.runKind === "countdown") TimerService.stopCountdown()
                else TimerService.stopStopwatch()
            }
        }
    }

'''

ANCHOR = '''    RowLayout {
        Layout.fillWidth: true
        spacing: 6 * root.d
        Repeater {
'''

if s.count(ANCHOR) != 1:
    sys.stderr.write("toolsclock.py: anchor not found:\n" + ANCHOR[:80] + "\n")
    sys.exit(1)
s = s.replace(ANCHOR, ROW + ANCHOR)

open(out, "w").write(s)
