import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:one_up/constants.dart';
import 'package:one_up/content.dart';
import 'package:one_up/debug.dart';
import 'package:one_up/footer.dart';
import 'package:one_up/header.dart';
import 'package:one_up/sensors.dart';
import 'package:one_up/summary.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _deviceName = 'eSense-0151';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';
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

  Future<void> _connectToESense() async {
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

    con = await ESenseManager.connect(_deviceName);

    setState(() {
      _deviceStatus = con ? 'connecting to $_deviceName' : 'connection failed';
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

  void setESenseName(String name) {
    setState(() {
      _deviceName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          HeaderPanel(_deviceName, setESenseName, _connectToESense, _tryingToConnect, ESenseManager.connected),
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
                    return SummaryCarousel([
                      ..._summaries.map((data) {
                        if (data.isFromToday) {
                          _todaysSummary = data;
                        }
                        return SummaryCard(data, _carouselController);
                      }),
                      ConnectionSummary(_deviceStatus, _voltage, _button, _event)
                    ],
                    _carouselController);
                }
              }),
          ActionsPanel(_connectToESense, _startWorkout, _finishWorkout, _tryingToConnect, _todaysSummary),
        ],
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

