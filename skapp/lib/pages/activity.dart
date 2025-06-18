import 'package:flutter/material.dart';
import 'package:skapp/widgets/custom_loader.dart';

class ActivityPage extends StatelessWidget {
  final ScrollController? scrollController;

  const ActivityPage({
    super.key,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: CustomLoader(),
            ),
            Text('Activity Page is being developed')
          ],
        ),
      ),
    );
  }
}
