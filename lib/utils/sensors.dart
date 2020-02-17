import 'dart:async';
import 'dart:collection';

import 'package:esense_flutter/esense.dart';
import 'package:one_up/vars/constants.dart';
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

  @override
  String toString() {
    return 'x ${this.x.toStringAsFixed(3)}' +
        '    y ${this.y.toStringAsFixed(3)}' +
        '    z ${this.z.toStringAsFixed(3)}';
  }

  toList() => [this.x, this.y, this.z];

  SensorValues operator +(SensorValues other) =>
      SensorValues(this.x + other.x, this.y + other.y, this.z + other.z);

  SensorValues operator -(SensorValues other) =>
      SensorValues(this.x - other.x, this.y - other.y, this.z - other.z);

  SensorValues operator /(number) =>
      SensorValues(this.x / number, this.y / number, this.z / number);

  SensorValues abs() => SensorValues(this.x.abs(), this.y.abs(), this.z.abs());

  bool operator >(other) {
    return this.x > other || this.y > other || this.z > other;
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

  CombinedSensorEvent.zero() {
    this.phone = SensorValues(0, 0, 0, onUpdate);
    this.eSense = SensorValues(0, 0, 0, onUpdate);
    this.timestamp = DateTime.now();
  }

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

class ActivityClassifier {
  ActivityClassifier(this.onActivity);

  // pre-processing
  int eSenseWindowSize = 50;
  double eSenseLowpassThreshold = 0.1;
  SensorValues eSenseMovingAverage;

  int phoneWindowSize = 100;
  double phoneLowpassThreshold = 0.3;
  SensorValues phoneMovingAverage;

  // activity conditions
  String currentActivity;
  String bodyPosture;
  List<String> compatibleActivities = List();
  List<List<SensorValues>> checkpoints = List();
  Timer inactivityTimer;

  void Function(String) onActivity;

  void setPosture() {
    if (phoneMovingAverage.x + 0.3 > phoneMovingAverage.z &&
        phoneMovingAverage.z > phoneMovingAverage.y)
      bodyPosture = STANDING;
    else if (phoneMovingAverage.y + 0.125 > phoneMovingAverage.x &&
        phoneMovingAverage.x > phoneMovingAverage.z)
      bodyPosture = CHEST_UP;
    else if (phoneMovingAverage.z > phoneMovingAverage.y &&
        phoneMovingAverage.y > phoneMovingAverage.x - 0.3)
      bodyPosture = CHEST_DOWN;
    else if (phoneMovingAverage.x > phoneMovingAverage.y &&
        phoneMovingAverage.y > phoneMovingAverage.z)
      bodyPosture = KNEES_BENT;
    else
      bodyPosture = null;
  }

  void push(List<CombinedSensorEvent> scope) {
    var result = scope.reversed
            .take(eSenseWindowSize)
            .map((event) => event.eSense)
            .reduce((a, b) => a + b) /
        (eSenseWindowSize);

    // eSense data changed
    bool anyChange = false;
    if (eSenseMovingAverage == null ||
        (result - eSenseMovingAverage).abs() > eSenseLowpassThreshold) {
      eSenseMovingAverage = result;
      anyChange = true;
    }

    if (phoneMovingAverage == null || !anyChange) {
      result = scope.reversed
              .take(phoneWindowSize)
              .map((event) => event.phone)
              .reduce((a, b) => a + b) /
          (phoneWindowSize);

      // phone data changed
      if (phoneMovingAverage == null ||
          (result - phoneMovingAverage).abs() > phoneLowpassThreshold) {
        phoneMovingAverage = result;
        anyChange = true;
        setPosture();
      }
    }

    // something changed => check for activity
    if (anyChange) classifyActivity();
  }

  void resetCheckpoints([Timer timer]) {
    timer?.cancel();
    checkpoints.clear();
    compatibleActivities.clear();
    if (currentActivity != NEUTRAL) submitActivity(NEUTRAL);
  }

  void prepNextCheckpoint([SensorValues data]) {
    inactivityTimer?.cancel();
    inactivityTimer = Timer.periodic(Duration(seconds: 3), resetCheckpoints);
    checkpoints.add([phoneMovingAverage, eSenseMovingAverage, data ?? null]);
    print('possible - $compatibleActivities');
    print('checkpoint - ${data ?? bodyPosture}');
  }

  void submitActivity(String name) {
    currentActivity = name;
    onActivity(name);
    if (name != NEUTRAL) {
      compatibleActivities = [name];
    }
  }

  void classifyActivity() {
    if (compatibleActivities.isEmpty) {
      resetCheckpoints();

      switch (bodyPosture) {
        case KNEES_BENT:
          compatibleActivities.add(SQUATS);
          break;
        case STANDING:
          compatibleActivities.add(PULLUPS);
          break;
        case CHEST_DOWN:
          compatibleActivities.add(PUSHUPS);
          break;
        case CHEST_UP:
          compatibleActivities.add(SITUPS);
          break;
        default:
          return;
      }
      prepNextCheckpoint();
    } else {
      var prevPhoneMovAvg = checkpoints.last[0];
      var prevESenseMovAvg = checkpoints.last[1];
      var prevDelta = checkpoints.last[2];
      var phoneDelta = phoneMovingAverage - prevPhoneMovAvg;

      if (compatibleActivities.contains(SITUPS)) {
        if (bodyPosture != CHEST_UP) {
          compatibleActivities.remove(SITUPS);
        } else {
          SensorValues eSenseDelta = eSenseMovingAverage - prevESenseMovAvg;
          if (checkpoints.length == 1) {
            prepNextCheckpoint(eSenseDelta);
          } else if (checkpoints.length == 2) {
            if (prevDelta.x.sign != eSenseDelta.x.sign) {
              prepNextCheckpoint(eSenseDelta);
            }
          } else if (checkpoints.length == 3) {
            if (prevDelta.x.sign != eSenseDelta.x.sign) {
              submitActivity(SITUPS);
              checkpoints.removeLast();
              checkpoints.removeLast();
              prepNextCheckpoint(eSenseDelta);
            }
          }
        }
      }

      if (compatibleActivities.contains(PUSHUPS)) {
        if (bodyPosture != CHEST_DOWN) {
          compatibleActivities.remove(PUSHUPS);
        } else if (checkpoints.length == 1) {
          prepNextCheckpoint(phoneDelta);
        } else if (checkpoints.length == 2) {
          if (prevDelta.y.sign != phoneDelta.y.sign) {
            prepNextCheckpoint(phoneDelta);
          }
        } else if (checkpoints.length == 3) {
          if (prevDelta.y.sign != phoneDelta.y.sign) {
            submitActivity(PUSHUPS);
            checkpoints.removeLast();
            checkpoints.removeLast();
            prepNextCheckpoint(phoneDelta);
          }
        }
      }

      if (compatibleActivities.contains(SQUATS)) {
        if (checkpoints.length == 1) {
          if (bodyPosture == KNEES_BENT)
            prepNextCheckpoint();
          else if (bodyPosture != STANDING) {
            compatibleActivities.remove(SQUATS);
          }
        } else if (checkpoints.length == 2) {
          if (bodyPosture == STANDING) {
            submitActivity(SQUATS);
            checkpoints.removeLast();
          } else if (bodyPosture != KNEES_BENT) {
            compatibleActivities.remove(SQUATS);
          }
        }
      }

      if (compatibleActivities.contains(PULLUPS)) {
        // knees bent too far, probably squats
        if (phoneMovingAverage.y > -0.5) {
          compatibleActivities.remove(PULLUPS);
        } else if (checkpoints.length == 1) {
          prepNextCheckpoint(phoneDelta);
        } else if (checkpoints.length == 2) {
          if (prevDelta.y.sign != phoneDelta.y.sign) {
            if (phoneDelta.y.sign < 0 &&
                phoneMovingAverage.y + 0.75 > phoneMovingAverage.z) {
              prepNextCheckpoint(phoneDelta);
            } else {
              compatibleActivities.remove(PULLUPS);
            }
          }
        } else if (checkpoints.length == 3) {
          if (prevDelta.y.sign != phoneDelta.y.sign) {
            if (phoneDelta.y.sign < 0 &&
                phoneMovingAverage.y + 0.75 > phoneMovingAverage.z) {
              submitActivity(PULLUPS);
              checkpoints.removeLast();
              checkpoints.removeLast();
              prepNextCheckpoint(phoneDelta);
            } else {
              compatibleActivities.remove(PULLUPS);
            }
          }
        }
      }
    }
  }
}
