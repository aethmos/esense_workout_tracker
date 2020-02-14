import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:one_up/vars/constants.dart';


class ConnectionSummary extends StatelessWidget {
  ConnectionSummary(this.deviceStatus, this.voltage, this.button, this.event);

  final String deviceStatus;
  final double voltage;
  final String button;
  final String event;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 460,
        width: 300,
        decoration: BoxDecoration(
          color: colorBg,
          boxShadow: elevationShadow,
          borderRadius: borderRadius,
        ),
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(25),
        child: Column(children: <Widget>[
          Icon(Icons.network_check),
          SensorDataDisplay(
            'Device Status:',
            deviceStatus,
          ),
          SensorDataDisplay(
            'Battery Level:',
            '${(min(voltage / 4000, 1) * 100).round()}%',
          ),
          SensorDataDisplay(
            'Button Pressed:',
            button,
          ),
          SensorDataDisplay(
            'Event Type:',
            event,
          ),
        ]));
  }
}

class SensorDataDisplay extends StatelessWidget {
  SensorDataDisplay(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text('$label', style: textHeading.copyWith(fontSize: 22)),
            Container(
              height: 5,
            ),
            Text(
              '$value',
              overflow: TextOverflow.clip,
              style: textHeading.copyWith(fontSize: 16),
            )
          ],
        ));
  }
}
