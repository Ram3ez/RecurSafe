import "package:flutter/cupertino.dart";
//import "package:flutter/material.dart";

class CustomItem extends StatelessWidget {
  const CustomItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Container(
        width: 170,
        decoration: ShapeDecoration(
          color: CupertinoColors.activeBlue,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadiusGeometry.circular(20),
          ),
        ),
      ),
    );
  }
}
