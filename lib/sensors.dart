import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:math';

import 'package:esense_flutter/esense.dart';
import 'package:moving_average/moving_average.dart';
import 'package:sensors/sensors.dart';

class SensorValues {
  double x;
  double y;
  double z;
  void Function() onUpdate;

  SensorValues(this.x, this.y, this.z, {this.onUpdate});

  update(x, y, z) {
    this.x = x;
    this.y = y;
    this.z = z;
    onUpdate();
  }
}

class CombinedSensorEvent {
  DateTime timestamp;
  SensorValues phone;
  SensorValues eSense;

  CombinedSensorEvent(phoneY, phoneX, phoneZ, eSenseX, eSenseY, eSenseZ) {
    this.phone = SensorValues(phoneY, phoneX, phoneZ, onUpdate: onUpdate);
    this.phone = SensorValues(eSenseX, eSenseY, eSenseZ, onUpdate: onUpdate);
    this.timestamp = DateTime.now();
  }

  onUpdate() {
    this.timestamp = DateTime.now();
  }

  @override
  String toString() {
    return 'Acceleration\n'
        + '  Phone\n'
        + '    x ${this.phone.x.toStringAsFixed(3)}\n'
        + '    y ${this.phone.y.toStringAsFixed(3)}\n'
        + '    z ${this.phone.z.toStringAsFixed(3)}\n'
        + '  eSense\n'
        + '    x ${this.eSense.x.toStringAsFixed(3)}\n'
        + '    y ${this.eSense.y.toStringAsFixed(3)}\n'
        + '    z ${this.eSense.z.toStringAsFixed(3)}';
  }
}

class SensorSubscription {
  int queueSize = 100;
  int windowSize = 15;
  Queue<AccelerometerEvent> phoneSensorSamples = Queue();
  Queue eSenseSensorSamples = Queue();

  Accelerometer phoneSubscription;
  StreamSubscription eSenseSubscription;
  CombinedSensorEvent combinedEvent;
  void Function(CombinedSensorEvent) onData;

  bool phoneSubscriptionIsPaused = true;

  SensorSubscription(this.onData);

  Future cancel() async {
    phoneSubscription?.stop();
    eSenseSubscription?.cancel();

    phoneSensorSamples.clear();
    eSenseSensorSamples.clear();
  }

//  dispatchEvent(event) {
//    if (event.runtimeType == AccelerometerEvent) {
//      onAccelerometerData(event);
//    } else {
//      oneSenseData(event);
//    }
//  }

  void onPhoneData(Event event) {
    print(event);

    phoneSensorSamples.addLast(event as AccelerometerEvent);
    if (phoneSensorSamples.length > queueSize) {
      phoneSensorSamples.removeFirst();

      var samplesAccelX = movingAverage(phoneSensorSamples.map((event) => event.x).toList(), windowSize, includePartial: true);
      var samplesAccelY = movingAverage(phoneSensorSamples.map((event) => event.y).toList(), windowSize, includePartial: true);
      var samplesAccelZ = movingAverage(phoneSensorSamples.map((event) => event.z).toList(), windowSize, includePartial: true);

      combinedEvent = combinedEvent.phone.update(samplesAccelX.reduce(max), samplesAccelY.reduce(max), samplesAccelZ.reduce(max));

      onData(combinedEvent);
    }
  }

  void oneSenseData(SensorEvent event) {
//      print('SENSOR event: $event');
    String summary = '' +
        '\nindex: ${event.packetIndex}' +
        '\ntimestamp: ${event.timestamp}' +
        '\naccel: ${event.accel}' +
        '\ngyro: ${event.gyro}';
    print(summary);

    eSenseSensorSamples.addLast(event);
    if (eSenseSensorSamples.length > queueSize) {
      eSenseSensorSamples.removeFirst();

      var samplesAccelX = movingAverage(eSenseSensorSamples.map((event) => event.x).toList(), windowSize, includePartial: true);
      var samplesAccelY = movingAverage(eSenseSensorSamples.map((event) => event.y).toList(), windowSize, includePartial: true);
      var samplesAccelZ = movingAverage(eSenseSensorSamples.map((event) => event.z).toList(), windowSize, includePartial: true);

      combinedEvent = combinedEvent.eSense.update(samplesAccelX.reduce(max), samplesAccelY.reduce(max), samplesAccelZ.reduce(max));

      onData(combinedEvent);
    }
  }

  bool get isPaused =>
      phoneSubscriptionIsPaused && eSenseSubscription.isPaused;

  void pause([Future resumeSignal]) {
    phoneSubscription?.stop();
    phoneSubscriptionIsPaused = true;
    eSenseSubscription?.pause();

    phoneSensorSamples.clear();
    eSenseSensorSamples.clear();
  }

  void resume() {
    phoneSubscription?.start();
    phoneSubscriptionIsPaused = false;
    eSenseSubscription?.resume();
  }
}

SensorSubscription listenToSensorEvents(Function onData) {
  var subscription = SensorSubscription(onData);

  subscription.phoneSubscription =
      Accelerometer()..addEventListener('data', subscription.onPhoneData);
  subscription.phoneSubscription.start();
  subscription.phoneSubscriptionIsPaused = false;

  if (ESenseManager.connected) {
    subscription.eSenseSubscription =
        ESenseManager.sensorEvents.listen(subscription.oneSenseData);
  }

  return subscription;
}
