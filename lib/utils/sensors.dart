import 'dart:async';
import 'dart:collection';

import 'package:esense_flutter/esense.dart';
import 'package:sensors/sensors.dart';

ActivitySubscription listenToActivityEvents(Function(String) onActivity) {
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

  SensorValues operator +(SensorValues other) =>
      SensorValues(this.x + other.x, this.y + other.y, this.z + other.z);

  SensorValues operator -(SensorValues other) =>
      SensorValues(this.x - other.x, this.y - other.y, this.z - other.z);

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

const String NEUTRAL = null;
const String SQUATS = 'Squats';
const String SITUPS = 'Sit-ups';
const String PUSHUPS = 'Push-ups';
const String PULLUPS = 'Pull-ups';

const String STANDING = 'Standing';
const String CHEST_UP = 'Chest Up';
const String CHEST_DOWN = 'Chest Down';
const String KNEES_BENT = 'Knees Bent';

class ActivityClassifier {
  ActivityClassifier(this.onActivity);

  // pre-processing
  int eSenseWindowSize = 50;
  double eSenseLowpassThreshold = 0.1;
  SensorValues eSenseMovingAverage;

  int phoneWindowSize = 100;
  double phoneLowpassThreshold = 0.3;
  SensorValues phoneMovingAverage;

  String bodyPosture;
  List<String> compatibleActivities = List();

  void Function(String) onActivity;

  List<List<dynamic>> checkpoints = List();
  Timer inactivityTimer;

  void setPosture() {
    if (phoneMovingAverage.x + 0.3 > phoneMovingAverage.z &&
        phoneMovingAverage.z > phoneMovingAverage.y)
      bodyPosture = STANDING;
    else if (phoneMovingAverage.y + 0.125 > phoneMovingAverage.x &&
        phoneMovingAverage.x > phoneMovingAverage.z)
      bodyPosture = CHEST_UP;
    else if (phoneMovingAverage.z > phoneMovingAverage.y &&
        phoneMovingAverage.y > phoneMovingAverage.x)
      bodyPosture = CHEST_DOWN;
    else if (phoneMovingAverage.x > phoneMovingAverage.y &&
        phoneMovingAverage.y > phoneMovingAverage.z) bodyPosture = KNEES_BENT;

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
      if ((result - phoneMovingAverage).abs() > phoneLowpassThreshold) {
        phoneMovingAverage = result;
        setPosture();
      }
    }

    // something changed => check for activity
    if (anyChange) classifyActivity();
  }

  void resetCheckpoints([Timer timer]) {
    timer?.cancel();
    compatibleActivities.clear();
    checkpoints.clear();
    onActivity(NEUTRAL);
  }

  void recordCheckpoint([SensorValues data]) {
    inactivityTimer?.cancel();
    inactivityTimer = Timer.periodic(Duration(seconds: 3), resetCheckpoints);
    checkpoints.add([phoneMovingAverage, eSenseMovingAverage, data ?? null]);
  }

  void classifyActivity() {
    if (compatibleActivities.isEmpty) {
      resetCheckpoints();

      switch (bodyPosture) {
        case STANDING:
          compatibleActivities.addAll([PULLUPS, SQUATS]);
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
      recordCheckpoint();
    } else {
      SensorValues prevPhoneMovAvg = checkpoints.last[0];
      SensorValues prevESenseMovAvg = checkpoints.last[1];
      SensorValues prevDelta = checkpoints.last[2];
      SensorValues phoneDelta = phoneMovingAverage - prevPhoneMovAvg;

      for (var activity in compatibleActivities.toList()) {
        switch (activity) {
          case SITUPS:
            if (bodyPosture != CHEST_UP) {
              compatibleActivities.remove(SITUPS);
              continue;
            }

            if (checkpoints.length == 1) {
              recordCheckpoint();
            } else {
              SensorValues eSenseDelta = eSenseMovingAverage - prevESenseMovAvg;
              if (checkpoints.length == 2) {
                // direction change 1: sit-up halfway
                if (prevDelta.x.sign != eSenseDelta.x.sign) {
                  recordCheckpoint(eSenseDelta);
                }
              } else if (checkpoints.length == 3) {
                // direction change 2: sit-up complete
                if (prevDelta.x.sign != eSenseDelta.x.sign) {
                  // sit-ups confirmed
                  compatibleActivities = [SITUPS];
                  onActivity(SITUPS);

                  checkpoints.removeLast();
                  checkpoints.removeLast();
                  recordCheckpoint(eSenseDelta);
                }
              }
            }
            break;

          case PUSHUPS:
            if (bodyPosture != CHEST_DOWN) {
              compatibleActivities.remove(PUSHUPS);
              continue;
            }

            if (checkpoints.length == 1) {
              recordCheckpoint(phoneDelta);
            } else if (checkpoints.length == 2) {
              // direction change 1: push-up halfway
              if (prevDelta.y.sign != phoneDelta.y.sign) {
                recordCheckpoint(phoneDelta);
              }
            } else if (checkpoints.length == 3) {
              // direction change 2: push-up complete
              if (prevDelta.y.sign != phoneDelta.y.sign) {
                compatibleActivities = [PUSHUPS];
                onActivity(PUSHUPS);

                checkpoints.removeLast();
                checkpoints.removeLast();
                recordCheckpoint(phoneDelta);
              }
            }
            break;

          case SQUATS:
            // knees held too far back, probably crooked pullups
            if (phoneMovingAverage.y < -0.5) {
              compatibleActivities.remove(SQUATS);
              continue;
            }

            if (checkpoints.length == 1) {
              recordCheckpoint(phoneDelta);
            } else if (checkpoints.length == 2) {
              // direction change 1: squat halfway
              if (prevDelta.y.sign != phoneDelta.y.sign) {
                // ensure knees are bent 90 degrees when going back up
                if (phoneDelta.y.sign < 0 &&
                    phoneMovingAverage.y + 0.125 > phoneMovingAverage.x &&
                    phoneMovingAverage.y > phoneMovingAverage.z) {
                  recordCheckpoint(phoneDelta);
                } else {
                  compatibleActivities.remove(SQUATS);
                  continue;
                }
              }
            } else if (checkpoints.length == 3) {
              // direction change 2: squat complete
              if (prevDelta.y.sign != phoneDelta.y.sign) {
                // ensure knees are bent 90 degrees when going back up
                if (phoneDelta.y.sign < 0 &&
                    phoneMovingAverage.y + 0.125 > phoneMovingAverage.x &&
                    phoneMovingAverage.y > phoneMovingAverage.z) {
                  // activity confirmed, remove others
                  compatibleActivities = [SQUATS];
                  onActivity(SQUATS);

                  checkpoints.removeLast();
                  checkpoints.removeLast();
                  recordCheckpoint(phoneDelta);
                } else {
                  compatibleActivities.remove(SQUATS);
                  continue;
                }
              }
            }
            break;

          case PULLUPS:
            // knees bent too far, probably squats
            if (phoneMovingAverage.y > -0.5) {
              compatibleActivities.remove(PULLUPS);
              continue;
            }

            if (checkpoints.length == 1) {
              recordCheckpoint(phoneDelta);
            } else if (checkpoints.length == 2) {
              // direction change 1: pull-up halfway
              if (prevDelta.y.sign != phoneDelta.y.sign) {
                recordCheckpoint(phoneDelta);
              }
            } else if (checkpoints.length == 3) {
              // direction change 2: pull-up complete
              if (prevDelta.y.sign != phoneDelta.y.sign) {
                if (phoneDelta.y.sign < 0 &&
                    phoneMovingAverage.y + 0.75 > phoneMovingAverage.z) {
                  // activity confirmed, remove others
                  compatibleActivities = [PULLUPS];
                  onActivity(PULLUPS);

                  checkpoints.removeLast();
                  checkpoints.removeLast();
                  recordCheckpoint(phoneDelta);
                } else {
                  compatibleActivities.remove(PULLUPS);
                  continue;
                }
              }
            }
            break;
        }
      }
    }
  }
}
