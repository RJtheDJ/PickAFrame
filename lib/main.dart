import 'package:flutter/material.dart';

// IGNORE THIS HERE I HAVE DONE TESTING WITH THIS CODE
// This is a simple Flutter application that simulates a painting and framing engine.
// feel free to try running it

void main() {
  runApp(const FramingApp());
}

class FramingApp extends StatelessWidget {
  const FramingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Frame Simulator',
      home: const FrameViewerScreen(),
    );
  }
}

class FrameViewerScreen extends StatefulWidget {
  const FrameViewerScreen({super.key});

  @override
  State<FrameViewerScreen> createState() => _FrameViewerScreenState();
}

// Logic of a painting and framing engine, with a simple UI to demonstrate the concept. 
// The frame and mat are represented as containers with shadows to simulate depth and realism.
class _FrameViewerScreenState extends State<FrameViewerScreen> {
  // Our dynamic variables (hardcoded)
  double frameWidth = 40.0;
  double matWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900], // The background
      appBar: AppBar(
        title: const Text('Basic Framing Engine'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // The Framing Area 
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Frame Container
                    Container(
                      padding: EdgeInsets.all(frameWidth), // Tied to variable
                      decoration: BoxDecoration(
                        color: Colors.brown[800],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(10, 15),
                          ),
                        ],
                        border: Border.all(color: Colors.black87, width: 2),
                      ),
                      
                      // Inner Mat Board Container
                      child: Container(
                        padding: EdgeInsets.all(matWidth), // Tied to variable
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 10,
                              spreadRadius: -2,
                              offset: Offset(0, 5),
                            )
                          ],
                        ),
                        
                        // Artwork Layer
                        child: Image.network(
                          'https://picsum.photos/600/400',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // The Control Panel 
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            // SafeArea ensures sliders don't get blocked by the phone's bottom navigation bar
            child: SafeArea(
              child: Column(
                children: [
                  
                  // Frame Width Slider Row 
                  Row(
                    children: [
                      const Text('Frame', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: frameWidth,
                          min: 10.0,
                          max: 120.0,
                          activeColor: Colors.brown[400],
                          // updates the variable and redraws the screen
                          onChanged: (newValue) {
                            setState(() {
                              frameWidth = newValue;
                            });
                          },
                        ),
                      ),
                      Text('${frameWidth.toInt()} px', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  
                  // Mat Width Slider Row
                  Row(
                    children: [
                      const Text('Mat    ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Spaces for alignment
                      Expanded(
                        child: Slider(
                          value: matWidth,
                          min: 0.0, // Allow users to remove the mat completely
                          max: 120.0,
                          activeColor: const Color(0xFFF5F5F0),
                          onChanged: (newValue) {
                            setState(() {
                              matWidth = newValue;
                            });
                          },
                        ),
                      ),
                      Text('${matWidth.toInt()} px', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
