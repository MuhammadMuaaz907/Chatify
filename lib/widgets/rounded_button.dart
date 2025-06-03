import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String name;
  final double height;
  final double width;
  final Function onPressed;
  final Color? buttonColor; // Optional parameter with default value
  final Color? textColor;  // Optional parameter with default value

  const RoundedButton({
    required this.name,
    required this.height,
    required this.width,
    required this.onPressed,
    this.buttonColor, // Made optional
    this.textColor,  // Made optional
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * 0.25),
        color: buttonColor ?? Color.fromRGBO(0, 82, 218, 1.0), // Use passed color or default
      ),
      child: TextButton(
        onPressed: () => onPressed(),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 22,
            color: textColor ?? Colors.white, // Use passed color or default
            height: 1.5,
          ),
        ),
      ),
    );
  }
}