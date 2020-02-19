import 'dart:async';

import 'package:one_up/model/sensor.dart';
import 'package:one_up/vars/constants.dart';

class ActivityClassifier {
  ActivityClassifier(this.onActivity);

  // pre-processing
  int eSenseWindowSize = 50;
  double eSenseLowpassThreshold = 0.1;
  SensorValues eSenseMovingAverage;

  int phoneWindowSize = 100;
  double phoneLowpassThreshold = 0.2;
  SensorValues phoneMovingAverage;

  // activity conditions
  String currentActivity;
  String bodyPosture;
  List<String> compatibleActivities = List();
  List<List<dynamic>> checkpoints = List();
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

  void prepNextCheckpoint([dynamic data]) {
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
    }
    if (checkpoints.isEmpty) {
      switch (bodyPosture) {
        case KNEES_BENT:
          compatibleActivities = [SQUATS];
          prepNextCheckpoint();
          break;
        case STANDING:
          compatibleActivities = [PULLUPS];
          prepNextCheckpoint();
          break;
        case CHEST_DOWN:
          compatibleActivities = [PUSHUPS];
          prepNextCheckpoint();
          break;
        case CHEST_UP:
          compatibleActivities = [SITUPS];
          prepNextCheckpoint(eSenseMovingAverage.z - eSenseMovingAverage.x - 0.15);
          break;
        default:
          return;
      }
    } else {
      var prevPhoneMovAvg = checkpoints.last[0];
      var prevESenseMovAvg = checkpoints.last[1];
      var prevDelta = checkpoints.last[2];
      var phoneDelta = phoneMovingAverage - prevPhoneMovAvg;

      if (compatibleActivities.contains(SITUPS)) {
        if (bodyPosture != CHEST_UP) {
          compatibleActivities.remove(SITUPS);
        } else {
          double currentDelta = eSenseMovingAverage.z - eSenseMovingAverage.x - 0.15;
          if (checkpoints.length == 1) {
            if (prevDelta.sign != currentDelta.sign)
              prepNextCheckpoint(currentDelta);
          } else if (checkpoints.length == 2) {
            if (prevDelta.sign != currentDelta.sign)
              prepNextCheckpoint(currentDelta);
          } else if (checkpoints.length == 3) {
            if (prevDelta.sign != currentDelta.sign) {
              submitActivity(SITUPS);
              checkpoints.removeLast();
              checkpoints.removeLast();
              prepNextCheckpoint(currentDelta);
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
