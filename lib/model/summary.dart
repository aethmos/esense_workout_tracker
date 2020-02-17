
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:one_up/vars/constants.dart';

class Summary {
  static String collectionName = 'summaries';
  static Set<String> ids = {};

  static int get totalCount => ids.length;

  String id;
  DateTime date;
  Map<String, int> counters;

  static Query get collection => Firestore.instance.collection(collectionName).orderBy('date', descending: true);

  factory Summary.fromDocument(DocumentSnapshot document) {
    return Summary(
        document.documentID,
        DateTime.fromMillisecondsSinceEpoch(document['date'].seconds * 1000),
        Map.from(document['counters']));
  }

  factory Summary.create() {
    return Summary(null, DateTime.now(), {
      SITUPS: 0,
      PUSHUPS: 0,
      PULLUPS: 0,
      SQUATS: 0,
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
      'date': this.date,
      'counters': this.counters
    }, merge: true);
    return this;
  }

  Summary reset() {
    print('resetting summary for date: ${humanReadableDate.format(this.date)}');
    for (var key in this.counters.keys) {
      this.counters[key] = 0;
    }
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

  String toAccessibleString() {
    String result = '';
    var entries = this.counters.entries.where((entry) => entry.value > 0);
    for (var entry in entries) {
      if (result != '') {
        if (entry.key == entries.last.key)
          result += ' and ';
        else
          result += ', ';
      }
      result += '${entry.value} ${entry.key}';
    }
    if (result == '')
      result = 'no exercise';
    return result;
  }
}
