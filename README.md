# OneUp - A Workout Tracker Application for eSense devices

This app will audibly count your Sit-ups, Push-ups, Squats and Jumping Jacks while you're doing them. When you're done, it will add them to a daily summary in a firestore database and read it back to you.

## Installation

### 1 Set up the Project
 - Clone the project
 - Open in Android Studio
 - Install Flutter Plugin with Dart SDK
 - Go into ```./pubspec.yaml```
 - Press ```Flutter upgrade``` and ```Packages get```

 ### 2 Set up Database
 - Right-click on ```./android/build.gradle > Flutter > Open for Editing in Android Studio```
 - Open the Gradle tab in the top-right corner
 - Get the keys by running the script at ```android/app/Tasks/android/signingReport```
 - Use the listed (debug) key to create a Google Firestore database with an empty ```summaries``` collection

### 3 Deploy and have Fun
 - Connect phone (I used a OnePlus 6T with Android 10)
 - Run or Debug ```./lib/main.dart```

## A Heads Up.
Turn both earables on, pair the main one (I used the left one). The second will connect automatically if it's turned on.
To reset both earables put them inside the charging case.
You *can* use both earable devices during the workout, but you *have* to use at least the **left** one (because only the left one is equipped with the necessary sensors).

Pressing the **earable button** will start/stop the workout and voice feedback will given respectively. The counted exercises are saved to the database every time you stop a workout.
In the **bottom bar**, you can also start/stop the workout, reset all counters for the day and toggle text-to-speech on/off.

The **phone placement** is crucial as it determines your starting position. (The eSense device is then used for triggering the activity.) The phone needs to be in your front pocket, with the screen facing away and the top of the phone facing your feet.

I'd recommend waiting 3 seconds in **between exercises**. You should then hear 'Resting' which means, the app is ready for another type of exercise.

If there is no workout for the current day, a new one will be created.
Workouts are **shared across all devices**. There are no accounts to separate the workouts.
