import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:one_up/constants.dart';
import 'package:one_up/sensors.dart';
import 'package:one_up/summary.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';
  final SpeechToText speech = SpeechToText();
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';

  bool _tryingToConnect = false;
  List<Summary> _summaries = new List();
  PageController _carouselController;
  Summary _todaysSummary;

//  bool _todaysSummaryInView = true;
  bool _workoutInProgress = false;

  @override
  void initState() {
    _initSummaries();
    _connectToESense();
    super.initState();
  }

  void _initSummaries() {
    Firestore.instance
        .collection('summaries')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      setState(() {
        _summaries = snapshot.documents.map((DocumentSnapshot document) {
          var summary = new Summary.fromDocument(document);
          print(summary.date);
          return summary;
        }).toList();
      });
      // add an empty summary for today if there is none
      if (!_summaries[_summaries.length - 1].isFromToday) {
        Summary.create().add();
      }
      _carouselController = PageController(
          initialPage: Summary.totalCount - 1,
          keepPage: false,
          viewportFraction: 300 / 370);
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _pauseListenToSensorEvents();
    ESenseManager.disconnect();
    super.dispose();
  }

  Future<void> _connectToESense({eSenseName = 'eSense-0151'}) async {
    bool con = false;

    // if you want to get the connection events when connecting, set up the listener BEFORE connecting...
    ESenseManager.connectionEvents.listen((event) {
      print('CONNECTION event: $event');

      // when we're connected to the eSense device, we can start listening to events from it
      if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        switch (event.type) {
          case ConnectionType.connected:
            _deviceStatus = 'connected';
            break;
          case ConnectionType.unknown:
            _deviceStatus = 'unknown';
            break;
          case ConnectionType.disconnected:
            _deviceStatus = 'disconnected';
            break;
          case ConnectionType.device_found:
            _deviceStatus = 'device_found';
            break;
          case ConnectionType.device_not_found:
            _deviceStatus = 'device_not_found';
            break;
        }
      });
    });

    setState(() {
      _tryingToConnect = true;
    });

    con = await ESenseManager.connect(eSenseName);

    setState(() {
      _deviceStatus = con ? 'connecting to $eSenseName' : 'connection failed';
      _tryingToConnect = false;
    });
  }

  void _listenToESenseEvents() async {
    ESenseManager.eSenseEvents.listen((event) {
      print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
//            _deviceName = (event as DeviceNameRead).deviceName;
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage;
            break;
          case ButtonEventChanged:
            if ((event as ButtonEventChanged).pressed) {
              _button = 'pressed';
              _workoutInProgress ? _finishWorkout() : _startWorkout();
            } else {
              _button = 'not pressed';
            }
            break;
          case AccelerometerOffsetRead:
            break;
          case AdvertisementAndConnectionIntervalRead:
            break;
          case SensorConfigRead:
            print((event as SensorConfigRead).toString());
        }
      });
    });
  }

  SensorSubscription sensorSubscription;

  void _startListenToSensorEvents() async {
    sensorSubscription = listenToSensorEvents((CombinedSensorEvent event) {
      print(event);
    });
  }

  void _pauseListenToSensorEvents() async {
    sensorSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _headerPanel(),
          StreamBuilder(
              stream: Summary.collection.snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError)
                  return new Text('Error: ${snapshot.error}');
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return new Text('Loading...');
                  default:
                    _summaries = snapshot.data.documents
                        .map((DocumentSnapshot document) {
                      var summary = Summary.fromDocument(document);
                      return summary;
                    }).toList();
                    return _snappyCarousel([
                      ..._summaries.map((data) {
                        if (data.isFromToday) {
                          _todaysSummary = data;
                        }
                        return SummaryCard(data, _carouselController);
                      }),
                      _connectionSummary()
                    ]);
                }
              }),
          _actionsPanel(),
        ],
      ),
    );
  }


  Widget _headerPanel() {
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
                (ESenseManager.connected)
                    ? Text('eSense-1585', style: textHeading)
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
                      initialValue: 'eSense-0151',
                      decoration: InputDecoration(
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        border: InputBorder.none,
                      ),
                      onFieldSubmitted: (String value) {
                        _connectToESense(eSenseName: value);
                      },
                    )),
                Container(
                    margin: EdgeInsets.only(top: 5),
                    child: Row(
                      children: (ESenseManager.connected)
                          ? [
                        Icon(Icons.check,
                            color: colorGood,
                            size: textSubheading.fontSize),
                        Text(
                          'Connected',
                          style: textSubheading,
                        )
                      ]
                          : _tryingToConnect
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
                onTap: () => ESenseManager.connected
                    ? ESenseManager.disconnect()
                    : _connectToESense(),
                child: Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      color: colorBg,
                      boxShadow: elevationShadowExtraLight,
                      borderRadius: borderRadius,
                    ),
                    child: Icon(
                      (ESenseManager.connected)
                          ? Icons.delete_outline
                          : Icons.bluetooth_searching,
                      color: textHeading.color,
                      size: 25,
                    )),
              )
            ]));
  }

  Widget _connectionSummary() {
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
          _sensorDataDisplay(
            'Device Status:',
            _deviceStatus,
          ),
          _sensorDataDisplay(
            'Battery Level:',
            '${(min(_voltage / 4000, 1) * 100).round()}%',
          ),
          _sensorDataDisplay(
            'Button Pressed:',
            _button,
          ),
          _sensorDataDisplay(
            'Event Type:',
            _event,
          ),
          _sensorDataDisplay(
            'Speech Input${speech.isListening ? ' - listening...' : ':'}',
            lastWords,
          )
        ]));
  }

  Widget _sensorDataDisplay(label, value) {
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

  Widget _snappyCarousel(List<Widget> items) {
    return Expanded(
        flex: 3,
        child: Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: PageView.builder(
//                onPageChanged: (int page) {
//                  if (page != Summary.totalCount - 1) {
//                    _finishWorkout();
//                  }
//                },
                controller: _carouselController,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) => items[index])));
  }

  Widget _actionsPanel() {
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
        children: _workoutInProgress
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
                onTap: () => _finishWorkout(),
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
              onTap: () => _todaysSummary.reset().submit(),
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
            onTap: () => _startWorkout(),
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
        onTap: () => _connectToESense(),
        child: Center(
            child: Text(
              'Connect',
              style: textCalendarDayToday,
            )),
      ),
    );
  }

  void _startWorkout() {
    if (!_workoutInProgress) {
      setState(() {
        _workoutInProgress = true;
      });

      // scroll relevant page into view
      _carouselController.animateToPage(Summary.totalCount - 1,
          duration: Duration(milliseconds: 1000), curve: ElasticOutCurve(1));

      // TODO start listening to sensor data + classify for activity
      _startListenToSensorEvents();
    }
  }

  void _finishWorkout() {
    if (!_workoutInProgress) {
      setState(() {
        _workoutInProgress = false;
      });
      _pauseListenToSensorEvents();

      // scroll relevant page into view
      _carouselController.animateToPage(Summary.totalCount - 1,
          duration: Duration(milliseconds: 1000), curve: ElasticOutCurve(1));

      // submit results to database
      _todaysSummary.submit();

      // TODO stop listening to sensor data

    }
  }
}
