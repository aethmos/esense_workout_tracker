import 'dart:async';
import 'dart:collection';

import 'package:esense_flutter/esense.dart';
import 'package:one_up/model/sensor.dart';
import 'package:one_up/utils/classification.dart';
import 'package:sensors/sensors.dart';

class ActivitySubscription {
  ActivitySubscription(onEvent) {
    activityClassifier = ActivityClassifier(onEvent);
    phoneSubscription = accelerometerEvents.listen(onPhoneData);
    eSenseSubscription = ESenseManager.sensorEvents.listen(onSenseData);

    logTimer = Timer.periodic(Duration(seconds: 2), logEvent);
  }

  Timer logTimer;

  Queue<CombinedSensorEvent> syncedSensorEvents = Queue();
  int bufferSize = 100;

  StreamSubscription phoneSubscription;
  StreamSubscription eSenseSubscription;
  CombinedSensorEvent combinedEvent = CombinedSensorEvent.zero();
  ActivityClassifier activityClassifier;

  Future cancel() async {
    phoneSubscription?.cancel();
    eSenseSubscription?.cancel();
    logTimer?.cancel();

    syncedSensorEvents.clear();
  }

  void logEvent(Timer timer) {
    if (!isPaused) {
      print('');
      print('${activityClassifier.bodyPosture}');
      print('phone  ${activityClassifier.phoneMovingAverage}');
      print('eSense ${activityClassifier.eSenseMovingAverage}');
    }
  }

  void submitEvent(CombinedSensorEvent event) {
//    print(event);
    syncedSensorEvents.addLast(event);
    if (syncedSensorEvents.length > bufferSize) {
      syncedSensorEvents.removeFirst();
      activityClassifier.push(syncedSensorEvents.toList());
    }
  }

  void onPhoneData(AccelerometerEvent event) {
    combinedEvent.phone.update(event.x / 10, event.y / 10, event.z / 10);
    submitEvent(combinedEvent);
  }

  void onSenseData(SensorEvent event) {
    combinedEvent.eSense.update(
        event.accel[0] / 10000, event.accel[1] / 10000, event.accel[2] / 10000);
    submitEvent(combinedEvent);
  }

  bool get isPaused =>
      phoneSubscription.isPaused && eSenseSubscription.isPaused;

  void pause([Future resumeSignal]) {
    phoneSubscription?.pause();
    eSenseSubscription?.pause();

    syncedSensorEvents.clear();
  }

  void resume() {
    if (phoneSubscription == null)
      phoneSubscription = accelerometerEvents.listen(onPhoneData);
    else
      phoneSubscription.resume();

    if (eSenseSubscription == null)
      eSenseSubscription = ESenseManager.sensorEvents.listen(onSenseData);
    else
      eSenseSubscription.resume();

    logTimer?.cancel();
    logTimer = Timer.periodic(Duration(seconds: 2), logEvent);
  }
}
