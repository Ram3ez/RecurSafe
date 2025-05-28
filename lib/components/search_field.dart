import "package:flutter/cupertino.dart";

class SearchField extends StatelessWidget {
  const SearchField({super.key, this.placeholder});
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      autofocus: true,
      placeholder: placeholder,
    );
  }
}
