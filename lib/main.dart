import 'dart:async';

import 'package:esense_flutter/esense.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

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
            Text('$value')
          ],
        ));
  }
}

class _MyAppState extends State<MyApp> {
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';

  // the name of the eSense device to connect to -- change this to your own device.
  String eSenseName = 'eSense-0332';

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
//    _connectToESense();
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

    con = await ESenseManager.connect(eSenseName);

    setState(() {
      _deviceStatus = con ? 'connecting' : 'connection failed';
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
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;
          case AccelerometerOffsetRead:
            // TODO
            break;
          case AdvertisementAndConnectionIntervalRead:
            // TODO
            break;
          case SensorConfigRead:
            // TODO
            break;
        }
      });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    // get the battery level every 10 secs
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

  void _startListenToSensorEvents() async {
    // subscribe to sensor event from the eSense device
    subscription = ESenseManager.sensorEvents.listen((event) {
      print('SENSOR event: $event');
      setState(() {
        _event = event.toString();
      });
    });
    setState(() {
      sampling = true;
    });
  }

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
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('eSense Demo App'),
        ),
        body: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Card(
                    margin: EdgeInsets.all(25),
                    elevation: 10,
//                    shape: Border.all(color: Colors.red, width: 1),
                    color: Colors.black38,
                    child: Padding(
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
                      ]),
                    ))
              ],
            )
          ],
        ),
//
//        Align(
//          alignment: Alignment.center,
//          child: Column(
//            mainAxisAlignment: MainAxisAlignment.start,
//            crossAxisAlignment: CrossAxisAlignment.center,
//            children: [
//              Card(
//                child: Row(
//                  children: <Widget>[
//                    Text('eSense Device Status:'),
//                    Text('\t$_deviceStatus')
//                  ],
//                ),
//              ),
//
//            ],
//          ),
//        ),
        floatingActionButton: new FloatingActionButton(
          // a floating button that starts/stops listening to sensor events.
          // is disabled until we're connected to the device.
          onPressed: (!ESenseManager.connected)
              ? null
              : (!sampling)
                  ? _startListenToSensorEvents
                  : _pauseListenToSensorEvents,
          tooltip: 'Listen to eSense sensors',
          child: (!sampling) ? Icon(Icons.hearing) : Icon(Icons.pause),
        ),
      ),
    );
  }
}
