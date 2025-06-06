import 'package:flutter/material.dart';
import 'package:skapp/widgets/custom_loader.dart';

class LoaderTestPage extends StatelessWidget {
  const LoaderTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Loader Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Button Loader:'),
            SizedBox(height: 20),
            CustomLoader(isButtonLoader: true),
            SizedBox(height: 40),
            Text('Full Loader:'),
            SizedBox(height: 20),
            CustomLoader(),
          ],
        ),
      ),
    );
  }
}
