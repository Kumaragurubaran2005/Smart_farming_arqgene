import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showAppBar;

  const AppBackground({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              title: title != null
                  ? Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: actions,
            )
          : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: child,
        ),
      ),
    );
  }
}
