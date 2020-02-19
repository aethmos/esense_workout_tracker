import 'dart:math';
import 'dart:ui';

import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_up/vars/constants.dart';


class HeaderPanel extends StatelessWidget {
  HeaderPanel(this.eSenseName, this.setESenseName, this.connectToESense, this.tryingToConnect, this.isConnected, this.voltage);

  final String eSenseName;
  final void Function(String eSenseName) setESenseName;
  final void Function() connectToESense;
  final bool tryingToConnect;
  final bool isConnected;
  final double voltage;

  void connect(_) => connectToESense;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 100,
        width: 300,
        decoration: BoxDecoration(
          color: colorBg,
          boxShadow: elevationShadow,
          borderRadius: borderRadius,
        ),
        margin: EdgeInsets.only(top: 60),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                (isConnected)
                    ? Text(eSenseName, style: textHeading)
                    : Container(
                    width: 165,
                    padding: EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                        color: colorBg,
                        boxShadow: elevationShadowLight,
                        borderRadius: borderRadius),
                    child: TextFormField(
                      style: textHeading.copyWith(color: colorFgLight),
                      autofocus: false,
                      autocorrect: false,
                      showCursor: true,
                      cursorRadius: Radius.circular(3),
                      textCapitalization: TextCapitalization.none,
                      initialValue: eSenseName,
                      decoration: InputDecoration(
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        border: InputBorder.none,
                      ),
                      onChanged: setESenseName,
                      onFieldSubmitted: connect,
                    )),
                Container(
                    margin: EdgeInsets.only(top: 5),
                    child: Row(
                      children: (isConnected)
                          ? [
                        Icon(Icons.check,
                            color: colorGood,
                            size: textSubheading.fontSize),
                        Text(
                          'Connected' + (voltage > 0 ? ' - ${(min(voltage / 4.2, 1) * 100).round()}%' : ''),
                          style: textSubheading,
                        )
                      ]
                          : tryingToConnect
                          ? [
                        Icon(Icons.timelapse,
                            color: colorNeutral,
                            size: textSubheading.fontSize),
                        Text(
                          'Connecting...',
                          style: textSubheading,
                        )
                      ]
                          : [],
                    ))
              ]),
              GestureDetector(
                onTap: isConnected ? ESenseManager.disconnect : connectToESense,
                child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: colorBg,
                      boxShadow: elevationShadowExtraLight,
                      borderRadius: borderRadius,
                    ),
                    child: Icon(
                      (isConnected)
                          ? Icons.phonelink_erase
                          : Icons.bluetooth_searching,
                      color: textHeading.color,
                      size: 25,
                    )
                )
                ,
              )
            ]
        )
    );
  }
}
