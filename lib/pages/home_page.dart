//import 'package:cupertino_onboarding/cupertino_onboarding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recursafe/components/custom_item.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(largeTitle: Text("Home")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Spacer(),
              SizedBox(height: 60),
              Text("Recently Added", style: TextStyle(fontSize: 30)),
              SizedBox(
                height: 150,

                child: ListView.builder(
                  itemCount: 4,
                  scrollDirection: Axis.horizontal,
                  itemBuilder:
                      (BuildContext context, int index) => CustomItem(),
                ),
              ),
              SizedBox(height: 20),
              Text("Recently Opened", style: TextStyle(fontSize: 30)),
              SizedBox(
                height: 150,

                child: ListView.builder(
                  itemCount: 4,
                  scrollDirection: Axis.horizontal,
                  itemBuilder:
                      (BuildContext context, int index) => CustomItem(),
                ),
              ),
              Spacer(flex: 6),
            ],
          ),
        ),
      ),
    );
  }
}
