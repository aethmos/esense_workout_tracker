import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';

final colorBg = Color(0xFFEAEAEA);

final colorFgLight = Color(0xFF707070);
final colorFg = Color(0xFF1E1E1E);
final colorFgBold = Color(0xFF1A1A1A);

final colorAccent = Color(0xFF8E00CC);

final colorGradientBegin = Color(0xFFB143E0);
final colorGradientEnd = Color(0xFFF6009B);

final colorAccentBorder = Color(0xFF8E00CC).withOpacity(0.5);
final colorShadowDark = Color(0xFF000000).withOpacity(0.16);
final colorShadowLight = Color(0xFFFFFFFF).withOpacity(0.8);

final colorGood = Color(0xFF19C530);
final colorNeutral = Color(0xFFE6A100);
final colorDanger = Color(0xFFE1154B);

final textCalendarDayToday = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 35,
  color: colorAccent,
);
final textCalendarDay = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 35,
  color: colorFgBold,
);
final textCalendarMonth = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w300,
  fontSize: 16,
  color: colorFgLight,
);

final textActivityLabel = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 28,
  color: colorFgBold,
);
final textActivityCounter = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w500,
  fontSize: 35,
  color: colorAccent,
);

final textHeading = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w300,
  fontSize: 26,
  color: colorFg,
);
final textSubheading = TextStyle(
  fontFamily: "Jost*",
  fontWeight: FontWeight.w300,
  fontSize: 16,
  color: colorFgLight,
);

final borderRadius = BorderRadius.circular(12.00);

final elevationShadow = [
  BoxShadow(
    offset: Offset(-3.00, -3.00),
    color: colorShadowLight,
    blurRadius: 6,
  ),
  BoxShadow(
    offset: Offset(3.00, 3.00),
    color: colorShadowDark,
    blurRadius: 6,
  ),
];

final elevationShadowLight = [
  BoxShadow(
    offset: Offset(-2.00, -2.00),
    color: colorShadowLight,
    blurRadius: 2,
  ),
  BoxShadow(
    offset: Offset(2.00, 2.00),
    color: colorShadowDark,
    blurRadius: 2,
  ),
];

final elevationShadowExtraLight = [
  BoxShadow(
    offset: Offset(-1.00, -1.00),
    color: colorShadowLight,
    blurRadius: 1,
  ),
  BoxShadow(
    offset: Offset(1.00, 1.00),
    color: colorShadowDark,
    blurRadius: 1,
  ),
];

class SensorDataDisplay extends StatelessWidget {
  final label;
  final value;

  const SensorDataDisplay({Key key, this.label, this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(top: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text('$label',
                style: TextStyle(
                    fontSize: Theme.of(context).textTheme.title.fontSize)),
            Container(
              height: 5,
            ),
            Text('$value', overflow: TextOverflow.clip)
          ],
        ));
  }
}

final humanReadable = DateFormat('yyyy-MM-dd');

class Summary {
  static String collectionName = 'summaries';
  static Set<String> ids = {};

  static int get totalCount => ids.length;

  String id;
  DateTime date;
  Map<String, int> counters;

  static get collection => Firestore.instance.collection(collectionName);

  factory Summary.fromDocument(DocumentSnapshot document) {
    return Summary(
        document.documentID,
        DateTime.fromMillisecondsSinceEpoch(document['date'].seconds * 1000),
        Map.from(document['counters']));
  }

  factory Summary.create() {
    return Summary(null, DateTime.now(), {
      'Sit-ups': 0,
      'Push-ups': 0,
      'Pull-ups': 0,
      'Squats': 0,
    });
  }

  Summary(this.id, this.date, this.counters) {
    if (!ids.contains(this.id)) {
      ids.add(this.id);
    }
  }

  Future<Summary> add() async {
    DocumentReference docRef = await Firestore.instance
        .collection(collectionName)
        .add({'date': this.date, 'counters': this.counters});
    this.id = docRef.documentID;
    return this;
  }

  Future<Summary> pull() async {
    DocumentSnapshot docRef = await Firestore.instance
        .collection(collectionName)
        .document(this.id)
        .get();
    return Summary.fromDocument(docRef);
  }

  Future<Summary> submit() async {
    if (this.id == null) {
      this.add();
    }
    await Firestore.instance
        .collection(collectionName)
        .document(this.id)
        .setData({
      'date': this.date.millisecondsSinceEpoch,
      'counters': this.counters
    }, merge: true);
    return this;
  }

  Summary reset() {
    this.counters.keys.map((key) => this.counters[key] = 0);
    return this;
  }

  Summary increment(String label) {
    this.counters[label] += 1;
    return this;
  }

  Summary decrement(String label) {
    this.counters[label] -= 1;
    return this;
  }

  bool get isFromToday {
    final today = DateTime.now();
    return (this.date.year == today.year &&
        this.date.month == today.month &&
        this.date.day == today.day);
  }
}

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';
  final SpeechToText speech = SpeechToText();
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  bool sessionInProgress = false;
  bool tryingToConnect = false;
  List<Summary> _summaries = new List();
  PageController _carouselController;
  Summary _todaysSummary;

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
      _summaries = snapshot.documents.map((DocumentSnapshot document) {
        var summary = new Summary.fromDocument(document);
        print(summary.date);
        return summary;
      }).toList();
      // add an empty summary for today if there is none
      if (!_summaries[_summaries.length - 1].isFromToday) {
        _carouselController = PageController(
            initialPage: _summaries.length,
            keepPage: true,
            viewportFraction: 300 / 370);
        Summary.create().add();
      } else {
        _carouselController = PageController(
            initialPage: _summaries.length - 1,
            keepPage: true,
            viewportFraction: 300 / 370);
      }
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

    tryingToConnect = true;
    con = await ESenseManager.connect(eSenseName);

    setState(() {
      _deviceStatus = con ? 'connecting to $eSenseName' : 'connection failed';
    });
    tryingToConnect = false;
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
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
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

    _getESenseProperties();
  }

//  void _startListenToSensorEvents() async {
//    // subscribe to sensor event from the eSense device
//    subscription = ESenseManager.sensorEvents.listen((event) {
//      print('SENSOR event: $event');
//      setState(() {
//        String summary = '';
//        summary += '\nindex: ${event.packetIndex}';
//        summary += '\ntimestamp: ${event.timestamp}';
//        summary += '\naccel: ${event.accel}';
//        summary += '\ngyro: ${event.gyro}';
//        _event = summary;
//      });
//    });
//    setState(() {
//      sampling = true;
//    });

  void _getESenseProperties() async {
    Timer.periodic(Duration(seconds: 10),
        (timer) async => await ESenseManager.getBatteryVoltage());

    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
    // it seems like the eSense BTLE interface does NOT like to get called
    // several times in a row -- hence, delays are added in the following calls
    Timer(
        Duration(seconds: 2), () async => await ESenseManager.getDeviceName());
    Timer(Duration(seconds: 3),
        () async => await ESenseManager.getAccelerometerOffset());
    Timer(
        Duration(seconds: 4),
        () async =>
            await ESenseManager.getAdvertisementAndConnectionInterval());
    Timer(Duration(seconds: 5),
        () async => await ESenseManager.getSensorConfig());
  }

  StreamSubscription subscription;

//  }

  void _pauseListenToSensorEvents() async {
    subscription.cancel();
    setState(() {
      sampling = false;
    });
  }

  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: colorBg, //top bar color
      statusBarIconBrightness: Brightness.dark, //top bar icons
      systemNavigationBarColor: colorBg, //bottom bar color
      systemNavigationBarIconBrightness: Brightness.dark, //bottom bar icons
    ));
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      themeMode: ThemeMode.light,
      title: '1up',
      home: Scaffold(
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
                        ..._summaries.map(
                            (data) {
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
          Icon(Icons.info_outline),
          SensorDataDisplay(
            label: 'Device Status:',
            value: _deviceStatus,
          ),
          SensorDataDisplay(
            label: 'Device Name:',
            value: _deviceName,
          ),
          SensorDataDisplay(
            label: 'Battery Level:',
            value: _voltage,
          ),
          SensorDataDisplay(
            label: 'Button Pressed:',
            value: _button,
          ),
          SensorDataDisplay(
            label: 'Event Type:',
            value: _event,
          ),
          SensorDataDisplay(
            label:
                'Speech Input${speech.isListening ? ' - listening...' : ':'}',
            value: lastWords,
          )
        ]));
  }

  Widget _snappyCarousel(List<Widget> items) {
    return Expanded(
        flex: 3,
        child: Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: PageView.builder(
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
              children: sessionInProgress
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
                              child:
                                  Icon(Icons.check, color: colorFgBold, size: 60),
                            ),
                          )),
                    ]
                  : <Widget>[
                      GestureDetector(
                        onTap: () => _todaysSummary.reset().submit(),
                        child: Icon(Icons.settings_backup_restore,
                            color: colorFgBold, size: 30),
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
                      Icon(Icons.edit, color: colorFgBold, size: 30),
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
    // TODO start listening to sensor data + classify for activity
  }

  void _finishWorkout() {
    _todaysSummary.submit();
    // TODO stop listening to sensor data
  }
}

class SummaryCard extends StatefulWidget {
  final Summary summary;
  final PageController controller;

  const SummaryCard(this.summary, this.controller);

  @override
  _SummaryCardState createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  Summary _summary;

  @override
  void initState() {
    setState(() {
      _summary = widget.summary;
    });
    super.initState();
  }

  void resetCounters() {
    setState(() {
      _summary = widget.summary.reset();
    });
  }

  void incrementActivity(String label) {
    setState(() {
      _summary = widget.summary.increment(label);
    });
  }

  void decrementActivity(String label) {
    setState(() {
      _summary = widget.summary.decrement(label);
    });
  }

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
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
//              Icon(Icons.insert_chart,
//                  color: colorFgBold, size: textHeading.fontSize * 1.5),
              SizedBox(width: 5),
              Text(
                'Overview',
                style: textHeading,
              ),
              SizedBox(width: 20),
              _calendarTile(_summary.date)
            ]),
        Expanded(
          child: Container(
            width: 200,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _summary.counters.entries
                        .map((entry) =>
                            _counterDisplay(entry.key.toString(), entry.value))
                        .toList() ??
                    []),
          ),
        )
      ]),
    );
  }

  Widget _calendarTile(DateTime date) {
    if (date == null) {
      date = DateTime.now();
    }
    var month = DateFormat('MMM');
    var day = DateFormat('dd');

    var today = DateTime.now();
    bool isToday = today.day == date.day && today.month == date.month;

    return GestureDetector(
      onTap: () => widget.controller.animateToPage(Summary.totalCount - 1,
          duration: Duration(milliseconds: 1000),
          curve: const ElasticOutCurve(1)),
      child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: colorBg,
            boxShadow: elevationShadowLight,
            borderRadius: borderRadius,
          ),
          child: Column(children: <Widget>[
            Text(day.format(date),
                style: isToday ? textCalendarDayToday : textCalendarDay),
            Text(month.format(date).toUpperCase(), style: textCalendarMonth)
          ])),
    );
  }

  Widget _counterDisplay(String label, int value) {
    return new Container(
        margin: EdgeInsets.only(top: 20),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text('$label',
                  style:
                      textActivityLabel.copyWith(fontWeight: FontWeight.w400)),
              Text('$value', style: textActivityCounter),
            ]));
  }
}
