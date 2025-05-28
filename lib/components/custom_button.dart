import "package:flutter/cupertino.dart";

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
  });
  final Widget child;
  final void Function()? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton.filled(
      onPressed: onPressed,
      color: color ?? CupertinoColors.systemBlue,
      child: child,
    );
  }
}
