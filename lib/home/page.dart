import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:one_up/home/center.dart';
import 'package:one_up/home/footer.dart';
import 'package:one_up/home/header.dart';
import 'package:one_up/model/summary.dart';
import 'package:one_up/utils/sensorInfo.dart';
import 'package:one_up/utils/sensors.dart';
import 'package:one_up/vars/constants.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Key key;
  ActivitySubscription _activitySubscription;
  StreamSubscription _summarySubscription;
  String _deviceName = 'eSense-0151';
  double _voltage = -1;
  String _deviceStatus = '';
  String _event = '';
  String _button = 'not pressed';
  bool _sampling = false;

  bool _tryingToConnect = false;
  List<Summary> _summaries = new List();
  Summary _currentSummary;
  PageController _carouselController;

//  bool _currentSummaryInView = true;
  bool _workoutInProgress = false;

  int _currentPage = 0;

  String _currentActivity;

  @override
  void dispose() {
    _carouselController.dispose();
    _activitySubscription?.cancel();
    _summarySubscription?.cancel();
    ESenseManager.disconnect();
    super.dispose();
  }

  @override
  void initState() {
    key = UniqueKey();
    _fetchSummaries();
    _connectESense();
    super.initState();
  }

  void _fetchSummaries() {
    _summarySubscription =
        Summary.collection.snapshots().listen((QuerySnapshot snapshot) {
      var summaries = snapshot.documents
          .map((DocumentSnapshot document) {
            var summary = new Summary.fromDocument(document);
            return summary;
          })
          .where((summary) =>
              summary.isFromToday ||
              summary.counters.values.reduce((a, b) => a + b) > 0)
          .toList();
      setSummaries(summaries);
    });
  }

  void setSummaries(List<Summary> summaries) async {
    // add an empty summary for today if there is none
    var latestSummary = summaries.first;
    var currentSummary = latestSummary.isFromToday
        ? latestSummary
        : await Summary.create().add();

    setState(() {
      _currentSummary = currentSummary;
      _summaries = summaries.reversed.toList();
    });
  }

  Future<void> _connectESense() async {
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
            _deviceName = (event as DeviceNameRead).deviceName;
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
            break;
        }
      });
    });
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
          HeaderPanel(_deviceName, setESenseName, _connectESense,
              _tryingToConnect, ESenseManager.connected),
          SummaryCarousel(
            key,
            _summaries,
            setCurrentPage,
            _currentActivity,
            ConnectionSummary(key, _deviceStatus, _voltage, _button, _currentActivity),
          ),
          ActionsPanel(_connectESense, _startWorkout, _finishWorkout,
              _tryingToConnect, _currentSummary),
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
      if (_activitySubscription == null) {
        _activitySubscription = listenToActivityEvents((String activity) {
          print(activity);
          setState(() {
            _currentActivity = activity;
            _currentSummary.counters[activity] += 1;
          });
        });
      } else {
        _activitySubscription.resume();
      }
    }
  }

  void _finishWorkout() {
    if (!_workoutInProgress) {
      setState(() {
        _workoutInProgress = false;
      });
      _activitySubscription?.pause();

      // scroll relevant page into view
      _carouselController.animateToPage(Summary.totalCount - 1,
          duration: Duration(milliseconds: 1000), curve: ElasticOutCurve(1));

      // submit results to database
      _currentSummary.submit();

      // TODO stop listening to sensor data

    }
  }

  void setCurrentPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }
}
