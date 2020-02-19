import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:one_up/vars/constants.dart';
import 'package:one_up/model/summary.dart';

class ActionsPanel extends StatelessWidget {
  ActionsPanel(
      this.isConnected,
      this.connectToESense,
      this.startWorkout,
      this.finishWorkout,
      this.workoutInProgress,
      this.currentSummary,
      this.resetSummary,
      this.textToSpeechEnabled,
      this.setTextToSpeech);

  final bool isConnected;
  final void Function() connectToESense;
  final void Function() startWorkout;
  final void Function() finishWorkout;
  final void Function() resetSummary;
  final bool workoutInProgress;
  final bool textToSpeechEnabled;
  final void Function(bool) setTextToSpeech;

  final Summary currentSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: 300,
      decoration: BoxDecoration(
        color: colorBg,
        boxShadow: elevationShadow,
        borderRadius: borderRadius,
      ),
      margin: EdgeInsets.only(bottom: 40),
      child: (isConnected)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: workoutInProgress
                  ? [
                      Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colorBg,
                            boxShadow: elevationShadowLight,
                            borderRadius: borderRadius,
                          ),
                          child: GestureDetector(
                            onTap: () => finishWorkout(),
                            child: Tooltip(
                              decoration:
                                  BoxDecoration(
                                      color: colorTooltipBg,
                                      borderRadius: borderRadius),
                              verticalOffset: -70,
                              message: 'Stop and Save Workout',
                              child: Center(
                                child: Icon(Icons.stop,
                                    color: Colors.red, size: 60),
                              ),
                            ),
                          )),
                    ]
                  : <Widget>[
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: resetSummary,
                          child: Tooltip(
                            decoration:
                                BoxDecoration(
                                    color: colorTooltipBg,
                                    borderRadius: borderRadius),
                            verticalOffset: -70,
                            message: "Reset Today's Workout",
                            child: Icon(Icons.delete_outline,
                                color: colorFgBold, size: 30),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => startWorkout(),
                        child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: colorBg,
                              boxShadow: elevationShadowLight,
                              borderRadius: borderRadius,
                            ),
                            child: Tooltip(
                              decoration:
                                  BoxDecoration(
                                      color: colorTooltipBg,
                                      borderRadius: borderRadius),
                              verticalOffset: -70,
                              message: 'Start Workout',
                              child: Center(
                                  child: Icon(Icons.play_arrow,
                                      color: colorAccent, size: 60)),
                            )),
                      ),
                      Expanded(
                          flex: 1,
                          child: GestureDetector(
                              onTap: () =>
                                  setTextToSpeech(!textToSpeechEnabled),
                              child: Tooltip(
                                decoration:
                                    BoxDecoration(
                                        color: colorTooltipBg,
                                        borderRadius: borderRadius),
                                verticalOffset: -70,
                                message: textToSpeechEnabled
                                    ? 'Turn off Text-to-speech'
                                    : 'Turn on Text-to-speech',
                                child: Icon(
                                    textToSpeechEnabled
                                        ? Icons.record_voice_over
                                        : Icons.volume_off,
                                    color: colorFgBold,
                                    size: 30),
                              ))),
                    ],
            )
          : GestureDetector(
              onTap: () => connectToESense(),
              child: Center(
                  child: Text(
                'Connect',
                style: textCalendarDayToday,
              )),
            ),
    );
  }
}
