import 'package:flutter/material.dart';

mixin AsyncActionMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> handleAsyncAction<R>(
    Future<R?> Function() asyncFunction,
    BuildContext context,
    {
    VoidCallback? onSuccess,
    String successMessage = 'Success',
    bool navigateOnSuccess = false,
    Widget? successPage,
  })
  async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await asyncFunction();

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // Optionally show a success message
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(successMessage),
          //     backgroundColor: Colors.green,
          //   ),
          // );

          if (onSuccess != null) {
            onSuccess();
          } else if (navigateOnSuccess && successPage != null) {
             Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => successPage),
            );
          }
        }
      } else {
        // Handle cases where the async function returns null but doesn't throw
        // (e.g., Google Sign-In cancelled)
         if (mounted) {
            // Optionally show a message for cancelled actions
            // ScaffoldMessenger.of(context).hideCurrentSnackBar();
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     content: Text('Action cancelled'),
            //     backgroundColor: Colors.orange,
            //   ),
            // );
         }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 