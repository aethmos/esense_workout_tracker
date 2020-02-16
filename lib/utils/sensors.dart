import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:esense_flutter/esense.dart';
import 'package:sensors/sensors.dart';

class SensorValues {
  double x;
  double y;
  double z;
  void Function() onUpdate;

  SensorValues(this.x, this.y, this.z, [this.onUpdate]);
  SensorValues.fromList(List list, [this.onUpdate]) {
    this.x = list[0];
    this.y = list[1];
    this.z = list[2];
  }

  update(x, y, z) {
    this.x = x;
    this.y = y;
    this.z = z;
    if (onUpdate != null) onUpdate();
  }

  toList() => [this.x, this.y, this.z];

  SensorValues operator +(SensorValues other) => SensorValues(this.x + other.x, this.y + other.y, this.z + other.z);

  SensorValues operator -(SensorValues other) => SensorValues(this.x - other.x, this.y - other.y, this.z - other.z);

  SensorValues operator /(number) => SensorValues(this.x / (number as double),
      this.y / (number as double), this.z / (number as double));

  SensorValues abs() => SensorValues(this.x.abs(), this.y.abs(), this.z.abs());

  bool operator >(other) {
    return this.x > other.x || this.y > other.y || this.z > other.z;
  }
  bool operator ==(other) {
    return this.x == other.x && this.y == other.y && this.z == other.z;
  }

  @override
  int get hashCode => super.hashCode;
}

class CombinedSensorEvent {
  DateTime timestamp;
  SensorValues phone;
  SensorValues eSense;

  CombinedSensorEvent(phoneY, phoneX, phoneZ, eSenseX, eSenseY, eSenseZ) {
    this.phone = SensorValues(phoneY, phoneX, phoneZ, onUpdate);
    this.eSense = SensorValues(eSenseX, eSenseY, eSenseZ, onUpdate);
    this.timestamp = DateTime.now();
  }

  onUpdate() {
    this.timestamp = DateTime.now();
  }

  @override
  String toString() {
    return 'Acceleration\n' +
        '  Phone\n' +
        '    x ${this.phone.x.toStringAsFixed(3)}\n' +
        '    y ${this.phone.y.toStringAsFixed(3)}\n' +
        '    z ${this.phone.z.toStringAsFixed(3)}\n' +
        '  eSense\n' +
        '    x ${this.eSense.x.toStringAsFixed(3)}\n' +
        '    y ${this.eSense.y.toStringAsFixed(3)}\n' +
        '    z ${this.eSense.z.toStringAsFixed(3)}';
  }
}

class ActivitySubscription {
  ActivitySubscription(onEvent)
      : this.activityClassifier = ActivityClassifier(onEvent);

  Queue<CombinedSensorEvent> syncedSensorEvents = Queue();
  int bufferSize = 100;

  StreamSubscription phoneSubscription;
  StreamSubscription eSenseSubscription;
  CombinedSensorEvent combinedEvent;
  ActivityClassifier activityClassifier;

  bool phoneSubscriptionIsPaused = true;

  Future cancel() async {
    phoneSubscription?.cancel();
    eSenseSubscription?.cancel();

    syncedSensorEvents.clear();
  }

  void submitEvent(CombinedSensorEvent event) {
    print(event);
    syncedSensorEvents.addLast(event);
    if (syncedSensorEvents.length > bufferSize) {
      syncedSensorEvents.removeFirst();
      activityClassifier.push(syncedSensorEvents.toList());
    }
  }

  void onPhoneData(AccelerometerEvent event) {
    combinedEvent = combinedEvent.phone.update(event.x, event.y, event.z);
    submitEvent(combinedEvent);
  }

  void oneSenseData(SensorEvent event) {
    combinedEvent = combinedEvent.eSense
        .update(event.accel[0], event.accel[1], event.accel[2]);
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
    phoneSubscription?.resume();
    eSenseSubscription?.resume();
  }
}

ActivitySubscription listenToActivityEvents(Function onActivity) {
  var subscription = ActivitySubscription(onActivity);

  subscription.phoneSubscription =
      accelerometerEvents.listen(subscription.onPhoneData);
  subscription.phoneSubscriptionIsPaused = false;

  if (ESenseManager.connected) {
    subscription.eSenseSubscription =
        ESenseManager.sensorEvents.listen(subscription.oneSenseData);
  }
  return subscription;
}

class Activity {
  Activity(this.name, this.scope);

  String name;
  bool inProgress = false;
  List<CombinedSensorEvent> scope = List<CombinedSensorEvent>();
}

class ActivityClassifier {
  ActivityClassifier(this.onActivity);

  // pre-processing
  int eSenseWindowSize = 50;
  double eSenseLowpassThreshold = 0.1;
  SensorValues eSenseMovingAverage;

  int phoneWindowSize = 100;
  double phoneLowpassThreshold = 0.3;
  SensorValues phoneMovingAverage;

  Activity currentActivity;

  void Function(ActivityClassifier) onActivity;

  void push(List<CombinedSensorEvent> scope) {
    var result = scope
        .reversed
        .take(eSenseWindowSize)
        .map((event) => event.eSense)
        .reduce((a,b) => a+b) / (phoneWindowSize);

    // eSense data changed
    if ((result - phoneMovingAverage).abs() > phoneLowpassThreshold) {
      phoneMovingAverage = result;

    } else {
      result = scope
          .reversed
          .take(phoneWindowSize)
          .map((event) => event.phone)
          .reduce((a,b) => a+b) / (phoneWindowSize);

      // phone data changed
      if ((result - phoneMovingAverage).abs() > phoneLowpassThreshold) {
        phoneMovingAverage = result;

      // no change
      } else {
        return;
      }
    }

    // something changed => check for activity
    classifyActivity();
  }

  void classifyActivity() {}
}
