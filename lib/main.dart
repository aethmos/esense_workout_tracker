import 'dart:async';
import 'dart:ui';

import 'package:esense_flutter/esense.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
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

final month2Name = Map.from({
  1: 'JAN',
  2: 'FEB',
  3: 'MAR',
  4: 'APR',
  5: 'MAY',
  6: 'JUN',
  7: 'JUL',
  8: 'AUG',
  9: 'SEP',
  10: 'OCT',
  11: 'NOV',
  12: 'DEC',
});

class SensorDataDisplay extends StatelessWidget {
  final label;
  final value;

  const SensorDataDisplay({Key key, this.label, this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
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

  get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColorDark: Colors.red,
        accentColor: Colors.red,
//      floatingActionButtonTheme: FloatingActionButtonThemeData(
//          backgroundColor: Colors.deepOrange
//      )
      );

  @override
  void initState() {
    super.initState();
    _connectToESense();
    setupRecognition();
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
//  }

  void _pauseListenToSensorEvents() async {
    subscription.cancel();
    setState(() {
      sampling = false;
    });
  }

  void dispose() {
    _pauseListenToSensorEvents();
    ESenseManager.disconnect();
    super.dispose();
  }

  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: colorBg, //top bar color
          statusBarIconBrightness: Brightness.dark, //top bar icons
          systemNavigationBarColor: colorBg, //bottom bar color
          systemNavigationBarIconBrightness: Brightness.dark, //bottom bar icons
        )
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      title: '1up',
      home: Scaffold(
        backgroundColor: colorBg,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // header
            Container(
                height: 100,
                width: 300,
                decoration: BoxDecoration(
                  color: colorBg,
                  boxShadow: elevationShadow,
                  borderRadius: borderRadius,
                ),
                margin: EdgeInsets.only(top: 40),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                      style: textHeading.copyWith(
                                          color: colorFgLight),
                                      autofocus: false,
                                      autocorrect: false,
                                      showCursor: true,
                                      cursorRadius: Radius.circular(3),
                                      textCapitalization:
                                          TextCapitalization.none,
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
                                                  size:
                                                      textSubheading.fontSize),
                                              Text(
                                                'Connecting...',
                                                style: textSubheading,
                                              )
                                            ]
                                          : [],
                                ))
                          ]),
                      Container(
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
                          ))
                    ])),

            // overview card
            Expanded(
                flex: 3,
                child: Container(
                    margin: EdgeInsets.only(top: 40, bottom: 40),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: BouncingScrollPhysics(),
                      children: <Widget>[
                        Container(width: 35),
                        Container(
                            height: 460,
                            width: 300,
                            decoration: BoxDecoration(
                              color: colorBg,
                              border: Border.all(
                                width: 1.00,
                                color: colorAccentBorder,
                              ),
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
                            ])),
                        SummaryCard(),
                        SummaryCard(),
                        Container(
                          width: 35,
                        ),
                      ],
                    ))),

            // actions
            Container(
              height: 80,
              width: 300,
              decoration: BoxDecoration(
                color: colorBg,
                boxShadow: elevationShadow,
                borderRadius: borderRadius,
              ),
              margin: EdgeInsets.only(bottom: 40),
//                    shape: Border.all(color: Colors.red, width: 1),
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
                                  child: Center(
                                    child: Icon(Icons.check,
                                        color: colorFgBold, size: 60),
                                  )),
                            ]
                          : <Widget>[
                              Icon(Icons.settings_backup_restore,
                                  color: colorFgBold, size: 30),
                              Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: colorBg,
                                    boxShadow: elevationShadowLight,
                                    borderRadius: borderRadius,
                                  ),
                                  child: Center(
                                    child: Icon(Icons.directions_run,
                                        color: colorFgBold, size: 50),
                                  )),
                              Icon(Icons.share, color: colorFgBold, size: 30),
                            ],
                    )
                  : Center(
                      child: Text(
                      'Connect',
                      style: textCalendarDayToday,
                    )),
            ),
          ],
        ),
//        floatingActionButton: new FloatingActionButton(
//          // a floating button that starts/stops listening to sensor events.
//          // is disabled until we're connected to the device.
//          onPressed: speech.isListening ? stopListening : startListening,
////          (!ESenseManager.connected)
////              ? _connectToESense
////              : (!sampling)
////                  ? _startListenToSensorEvents
////                  : _pauseListenToSensorEvents,
//          tooltip: 'Listen to eSense sensors',
//          child:
//              (!speech.isListening) ? Icon(Icons.hearing) : Icon(Icons.pause),
////          child: (!sampling) ? Icon(Icons.hearing) : Icon(Icons.pause),
//        ),
      ),
    );
  }

  void startListening() {
    lastWords = "";
    lastError = "";
    speech.listen(onResult: resultListener);
    setState(() {});
  }

  void stopListening() {
    speech.stop();
    setState(() {});
  }

  void cancelListening() {
    speech.cancel();
    setState(() {});
  }

  void resultListener(SpeechRecognitionResult result) {
    if (result.finalResult) {
      setState(() {
        lastWords = "${result.recognizedWords} - ${result.confidence}";
      });
      print(lastWords);
    }
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
    print(lastError);
  }

  void statusListener(String status) {
    setState(() {
      lastStatus = "$status";
    });
//    print(lastStatus);
  }

  Future<void> setupRecognition() async {
    bool available = await speech.initialize(
        onStatus: statusListener, onError: errorListener);
    if (available) {
      print("Speech recognition ready.");
//      speech.listen( onResult: resultListener );
    } else {
      print("The user has denied the use of speech recognition.");
    }
  }
}

class SummaryCard extends StatefulWidget {
  @override
  _SummaryCardState createState() => _SummaryCardState();
}

class _SummaryCardState extends State<StatefulWidget> {
//  int _sitUpCount = 0;
//  int _pushUpCount = 0;
//  int _pullUpCount = 0;
//  int _squatCount = 0;
//  int _burpeeCount = 0;
//
//  @override
//  void initState() {
//    setState(() {
//      _sitUpCount = 0;
//      _pushUpCount = 0;
//      _pullUpCount = 0;
//      _squatCount = 0;
//      _burpeeCount = 0;
//    });
//    super.initState();
//  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      width: 300,
      decoration: BoxDecoration(
        color: colorBg,
//        border: Border.all(
//          width: 1.00,
//          color: colorAccentBorder,
//        ),
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
              Container(width: 5),
              Text(
                'Overview',
                style: textHeading,
              ),
              Container(width: 20),
              CalendarTile()
            ]),
        Container(
          width: 200,
          margin: EdgeInsets.only(top: 30),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('Sit-ups',
                              style: textActivityLabel.copyWith(
                                  fontWeight: FontWeight.w400)),
                          Text('${0}', style: textActivityCounter),
                        ])),
                Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('Push-ups',
                              style: textActivityLabel.copyWith(
                                  fontWeight: FontWeight.w400)),
                          Text('${0}', style: textActivityCounter),
                        ])),
                Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('Pull-ups',
                              style: textActivityLabel.copyWith(
                                  fontWeight: FontWeight.w400)),
                          Text('${0}', style: textActivityCounter),
                        ])),
                Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('Squats',
                              style: textActivityLabel.copyWith(
                                  fontWeight: FontWeight.w400)),
                          Text('${0}', style: textActivityCounter),
                        ])),
                Container(
                    margin: EdgeInsets.only(top: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text('Burpees',
                              style: textActivityLabel.copyWith(
                                  fontWeight: FontWeight.w400)),
                          Text('${0}', style: textActivityCounter),
                        ])),
              ]),
        )
      ]),
    );
  }
}

class CalendarTile extends StatefulWidget {
  CalendarTile({Key key, day = 1, month = 1});

  @override
  _CalendarTileState createState() => _CalendarTileState();
}

class _CalendarTileState extends State<CalendarTile> {
  int day = 10;
  int month = 2;

  get isToday {
    var today = DateTime.now();
    return today.day == day && today.month == month;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: colorBg,
          boxShadow: elevationShadowLight,
          borderRadius: borderRadius,
        ),
        child: Column(children: <Widget>[
          Text(day > 9 ? '$day' : '0$day',
              style: isToday ? textCalendarDayToday : textCalendarDay),
          Text(month2Name[month], style: textCalendarMonth)
        ]));
  }
}
