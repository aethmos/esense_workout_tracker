import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:one_up/model/summary.dart';
import 'package:one_up/vars/constants.dart';

class SummaryCarousel extends StatefulWidget {
  SummaryCarousel(
      this.key, this.summaries, this.onPageChange, this.currentActivity,
      [this.debugCard])
      : super(key: key);

  final String currentActivity;
  final Key key;
  final List<Summary> summaries;
  final void Function(int) onPageChange;
  final Widget debugCard;

  @override
  _SummaryCarouselState createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<SummaryCarousel> {
  int currentPage = 10000;
  PageController controller;
  int itemCount = 0;

  int get lastPage => widget.summaries.length - 1;

  @override
  void initState() {
    controller = PageController(
        initialPage: 10000, // last page (true page count unknown at this point)
        keepPage: true,
        viewportFraction: 300 / 370);
    currentPage = widget.summaries.length - 1;
    super.initState();
  }

  setPage(int page) {
    setState(() {
      currentPage = page;
    });
    widget.onPageChange(page);
  }

  void animatePage(int page) {
    controller.animateToPage(page,
        duration: Duration(milliseconds: 1000),
        curve: const ElasticOutCurve(1));
  }

  @override
  Widget build(BuildContext context) {
    if (itemCount != widget.summaries.length) {
      itemCount = widget.summaries.length;
      animatePage(lastPage);
    }
    return Expanded(
        flex: 3,
        child: Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: PageView.builder(
                onPageChanged: setPage,
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                itemCount: widget.debugCard != null
                    ? widget.summaries.length + 1
                    : widget.summaries.length,
                itemBuilder: (context, index) {
                  if (index == widget.summaries.length) {
                    return widget.debugCard;
                  }
                  var summary = widget.summaries[index];
                  return SummaryCard(ValueKey(summary.id), summary, animatePage,
                      lastPage, widget.currentActivity);
                })));
  }
}

class SummaryCard extends StatefulWidget {
  const SummaryCard(this.key, this.summary, this.goToPage, this.lastPage,
      this.currentActivity)
      : super(key: key);
  final Key key;
  final Summary summary;
  final void Function(int page) goToPage;
  final int lastPage;
  final String currentActivity;

  @override
  _SummaryCardState createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
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
              _calendarTile(widget.summary.date)
            ]),
        Expanded(
          child: Container(
            width: 200,
            child: ListView(
                scrollDirection: Axis.vertical,
                children: widget.summary.counters.entries
                        .map((entry) => ActivityCounter(
                            entry.key.toString(),
                            entry.value,
                            widget.currentActivity == entry.key.toString()))
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

    return isToday
        ? Container(
            height: 60,
            width: 60,
            child: Column(children: <Widget>[
              Text(day.format(date), style: textCalendarDayToday),
              Text(month.format(date).toUpperCase(), style: textCalendarMonth)
            ]))
        : GestureDetector(
            onTap: () => widget.goToPage(widget.lastPage),
            child: Tooltip(
              decoration: BoxDecoration(
                  color: colorTooltipBg,
                  borderRadius: borderRadius),
              verticalOffset: -70,
              message: 'Go to Today',
              child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: colorBg,
                    boxShadow: elevationShadowLight,
                    borderRadius: borderRadius,
                  ),
                  child: Column(children: <Widget>[
                    Text(day.format(date), style: textCalendarDay),
                    Text(month.format(date).toUpperCase(),
                        style: textCalendarMonth)
                  ])),
            ),
          );
  }
}

class ActivityCounter extends StatelessWidget {
  ActivityCounter(this.label, this.value, [this.active = false]);

  final String label;
  final int value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return new Container(
        margin: EdgeInsets.only(top: 20),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
//              Text('${label.split(' ').join('\n')}',
              Text('${label.length < 10 ? label : label.split(' ').join('\n')}',
                  style: textActivityLabel.copyWith(
                      fontWeight: FontWeight.w400,
                      color: active ? colorAccent : textActivityLabel.color)),
              Text('$value', style: textActivityCounter),
            ]));
  }
}
