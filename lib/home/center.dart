import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SummaryCarousel extends StatelessWidget {
  SummaryCarousel(this.items, this.controller);

  final List<Widget> items;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: 3,
        child: Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: PageView.builder(
//                onPageChanged: (int page) {
//                  if (page != Summary.totalCount - 1) {
//                    _finishWorkout();
//                  }
//                },
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) => items[index])));
  }
}
