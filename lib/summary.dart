
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

class Summary {
  static String collectionName = 'summaries';
  static Set<String> ids = {};

  static int get totalCount => ids.length;

  String id;
  DateTime date;
  Map<String, int> counters;

  static get collection => Firestore.instance.collection(collectionName);

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

class SummaryCard extends StatefulWidget {
  final Summary summary;
  final PageController controller;

  const SummaryCard(this.summary, this.controller);

  @override
  _SummaryCardState createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  Summary _summary;

  @override
  void initState() {
    setState(() {
      _summary = widget.summary;
    });
    super.initState();
  }

  void resetCounters() {
    setState(() {
      _summary = widget.summary.reset();
    });
  }

  void incrementActivity(String label) {
    setState(() {
      _summary = widget.summary.increment(label);
    });
  }

  void decrementActivity(String label) {
    setState(() {
      _summary = widget.summary.decrement(label);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      width: 300,
      decoration: BoxDecoration(
        color: colorBg,
        boxShadow: elevationShadow,
        borderRadius: borderRadius,
      ),
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(25),
      child: Column(children: <Widget>[
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
//              Icon(Icons.insert_chart,
//                  color: colorFgBold, size: textHeading.fontSize * 1.5),
              SizedBox(width: 5),
              Text(
                'Overview',
                style: textHeading,
              ),
              SizedBox(width: 20),
              _calendarTile(_summary.date)
            ]),
        Expanded(
          child: Container(
            width: 200,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _summary.counters.entries
                    .map((entry) =>
                    _counterDisplay(entry.key.toString(), entry.value))
                    .toList() ??
                    []),
          ),
        )
      ]),
    );
  }

  Widget _calendarTile(DateTime date) {
    if (date == null) {
      date = DateTime.now();
    }
    var month = DateFormat('MMM');
    var day = DateFormat('dd');

    var today = DateTime.now();
    bool isToday = today.day == date.day && today.month == date.month;

    return GestureDetector(
      onTap: () => widget.controller.animateToPage(Summary.totalCount - 1,
          duration: Duration(milliseconds: 1000),
          curve: const ElasticOutCurve(1)),
      child: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color: colorBg,
            boxShadow: elevationShadowLight,
            borderRadius: borderRadius,
          ),
          child: Column(children: <Widget>[
            Text(day.format(date),
                style: isToday ? textCalendarDayToday : textCalendarDay),
            Text(month.format(date).toUpperCase(), style: textCalendarMonth)
          ])),
    );
  }

  Widget _counterDisplay(String label, int value) {
    return new Container(
        margin: EdgeInsets.only(top: 20),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text('$label',
                  style:
                  textActivityLabel.copyWith(fontWeight: FontWeight.w400)),
              Text('$value', style: textActivityCounter),
            ]));
  }
}
