import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SummaryCarousel extends StatefulWidget {
  SummaryCarousel(this.items, this.onPageChange);

  final List<Widget> items;
  final void Function(int) onPageChange;

  @override
  _SummaryCarouselState createState() => _SummaryCarouselState();
}

class _SummaryCarouselState extends State<SummaryCarousel> {
  int currentPage = 10000;
  PageController controller;

  @override
  void initState() {
    controller = PageController(
        initialPage: widget.items.length - 1 - 1,
        keepPage: true,
        viewportFraction: 300 / 370);
    currentPage = widget.items.length - 1;
    super.initState();
  }

  setPage(int page) {
    setState(() {
      currentPage = page;
    });
    widget.onPageChange(page);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        flex: 3,
        child: Container(
            margin: EdgeInsets.symmetric(vertical: 40),
            child: PageView.builder(
                onPageChanged: setPage,
                controller: controller,
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                itemCount: widget.items.length,
                itemBuilder: (context, index) => widget.items[index])));
  }
}
