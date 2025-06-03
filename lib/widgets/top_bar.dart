import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  final String _barTitle;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final double? fontSize;

  const TopBar(
    this._barTitle, {
    this.primaryAction,
    this.secondaryAction,
    this.fontSize = 35,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double deviceHeight = MediaQuery.of(context).size.height;
    final double deviceWidth = MediaQuery.of(context).size.width;
    return _buildUI(deviceHeight, deviceWidth);
  }

  Widget _buildUI(double deviceHeight, double deviceWidth) {
    return Container(
      height: deviceHeight * 0.10,
      width: deviceWidth,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (secondaryAction != null) secondaryAction!,
          _titleBar(),
          if (primaryAction != null) primaryAction!,
        ],
      ),
    );
  }

  Widget _titleBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Text(
        _barTitle,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}