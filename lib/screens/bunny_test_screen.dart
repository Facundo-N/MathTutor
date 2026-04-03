import 'package:flutter/material.dart';
import 'package:demo_33_v2/widgets/animated_bunny.dart';

void main() {
  runApp(const MaterialApp(home: BunnyTestScreen()));
}

class BunnyTestScreen extends StatelessWidget {
  const BunnyTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<AnimatedBunnyState> bunnyKey =
        GlobalKey<AnimatedBunnyState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bunny Animation Test')),
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBunny(
              key: bunnyKey,
              width: 400,
              height: 400,
              isSpeaking: false,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => bunnyKey.currentState?.greet(),
              child: const Text('GREET (Wave Arm)'),
            ),
          ],
        ),
      ),
    );
  }
}
