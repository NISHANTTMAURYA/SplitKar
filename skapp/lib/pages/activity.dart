import 'package:flutter/material.dart';
import 'package:skapp/widgets/custom_loader.dart';
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: CustomLoader(),
        ),
        Text('Activity Page is being developed')
      ],
    ));
  }
}
