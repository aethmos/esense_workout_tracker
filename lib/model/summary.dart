
import 'package:cloud_firestore/cloud_firestore.dart';

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
      'Sit-ups': 0,
      'Push-ups': 0,
      'Pull-ups': 0,
      'Squats': 0,
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
    this.counters.keys.map((key) => this.counters[key] = 0);
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
}
