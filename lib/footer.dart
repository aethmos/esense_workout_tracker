import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:one_up/constants.dart';
import 'package:one_up/summary.dart';


class ActionsPanel extends StatelessWidget {
  ActionsPanel(this.connectToESense, this.startWorkout, this.finishWorkout, this.workoutInProgress, this.todaysSummary);
  final void Function() connectToESense;
  final void Function() startWorkout;
  final void Function() finishWorkout;
  final bool workoutInProgress;
  final Summary todaysSummary;

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
      child: (ESenseManager.connected)
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
                child: Center(
                  child: Icon(Icons.check,
                      color: colorFgBold, size: 60),
                ),
              )),
        ]
            : <Widget>[
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => todaysSummary.reset().submit(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    transform: Matrix4.translationValues(10, 1, 0),
                    child: Icon(Icons.exposure_zero,
                        color: colorFgBold, size: 30),
                  ),
                  Text('.', style: textHeading),
                  Container(
                    transform: Matrix4.translationValues(-11, 1, 0),
                    child: Icon(Icons.exposure_zero,
                        color: colorFgBold, size: 30),
                  )
                ],
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
                child: Center(
                    child: new SvgPicture.asset(
                      'assets/sport.svg',
                      color: colorFgBold,
                      height: 45,
                      width: 45,
                    ))),
          ),
          Expanded(
              flex: 1,
              child: GestureDetector(
                  onTap: null,
                  child: Icon(Icons.edit,
                      color: colorFgBold, size: 30))),
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
