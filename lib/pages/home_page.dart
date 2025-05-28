//import 'package:cupertino_onboarding/cupertino_onboarding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recursafe/components/custom_button.dart';
import 'package:recursafe/components/custom_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(largeTitle: Text("Home")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: ListView(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Spacer(),
              SizedBox(height: 60),
              Text("Recently Added", style: TextStyle(fontSize: 30)),
              SizedBox(
                height: 130,

                child: ListView.builder(
                  itemCount: 4,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) =>
                      CustomItem(),
                ),
              ),
              SizedBox(height: 20),
              Text("Recently Opened", style: TextStyle(fontSize: 30)),
              SizedBox(
                height: 150,

                child: ListView.builder(
                  itemCount: 4,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) =>
                      CustomItem(),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Quick Shortcuts",
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  spacing: 20,
                  children: [
                    CustomButton(
                      onPressed: () {},
                      color: CupertinoColors.separator,
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(CupertinoIcons.add),
                          Icon(CupertinoIcons.folder_fill),
                        ],
                      ),
                    ),
                    CustomButton(
                      onPressed: () {},
                      color: CupertinoColors.separator,
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(CupertinoIcons.add),
                          Icon(
                            Icons.key,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              //Spacer(flex: 6),
            ],
          ),
        ),
      ),
    );
  }
}
