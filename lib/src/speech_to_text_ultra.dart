import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart';

class SpeechToTextUltra extends StatefulWidget {
  // final ValueChanged<String> callback;
  final Icon? toPauseIcon;
  final Icon? toStartIcon;
  final Color? pauseIconColor;
  final Color? startIconColor;
  final double? startIconSize;
  final double? pauseIconSize;
  final Function(String liveText, String finalText, bool isListening)
      ultraCallback;

  // String combinedResponse = '';
  const SpeechToTextUltra(
      {super.key,
      required this.ultraCallback,
      this.toPauseIcon = const Icon(Icons.pause),
      this.toStartIcon = const Icon(Icons.mic),
      this.pauseIconColor = Colors.black,
      this.startIconColor = Colors.black,
      this.startIconSize = 24,
      this.pauseIconSize = 24});

  @override
  State<SpeechToTextUltra> createState() => _SpeechToTextUltraState();
}

class _SpeechToTextUltraState extends State<SpeechToTextUltra> {
  late SpeechToText speech;
  bool isListening = false;
  String liveResponse = '';
  String entireResponse = '';
  String chunkResponse = '';

  @override
  void initState() {
    super.initState();
    speech = SpeechToText();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await speech.initialize(
      onStatus: (status) {
        debugPrint('Initialization status: $status');
      },
      onError: (errorNotification) {
        debugPrint('Initialization error: ${errorNotification.errorMsg}');
      },
    );
    debugPrint('Speech recognition available: $available');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isListening
          ? IconButton(
              iconSize: widget.pauseIconSize,
              icon: widget.toPauseIcon!,
              color: Colors.red,
              onPressed: () {
                stopListening();
              },
            )
          : IconButton(
              iconSize: widget.startIconSize,
              color: Colors.green,
              icon: widget.toStartIcon!,
              onPressed: () {
                startListening();
              },
            ),
    );
  }

  void startListening() async {
    debugPrint('START LISTENING ');
    debugPrint('isListening $isListening');
    debugPrint('chunkResponse $chunkResponse');
    debugPrint('liveResponse $liveResponse');
    debugPrint('entireResponse $entireResponse');
    debugPrint('is null ${speech == null}');

    // Check if speech is already initialized
    if (speech == null) {
      speech = SpeechToText();
    }

    bool available = await speech.initialize(
      onStatus: (status) async {
        debugPrint('onStatus ${status}');
        debugPrint(
            'Speech recognition status: $status AND is LISTENING STATUS ${isListening}');
        if ((status == "done" || status == "notListening") && isListening) {
          await speech.stop();
          setState(() {
            if (chunkResponse != '') {
              entireResponse = '$entireResponse $chunkResponse';
            }
            chunkResponse = '';
            liveResponse = '';
            //MAIN CALLBACK HAPPENS
            widget.ultraCallback(liveResponse, entireResponse, isListening);
          });
          startListening();
        }
      },
      onError: (errorNotification) {
        debugPrint('Speech recognition error: ${errorNotification.errorMsg}');
        setState(() {
          isListening = false;
          widget.ultraCallback(liveResponse, entireResponse, isListening);
        });
      },
    );

    if (available) {
      debugPrint('AVAILABLE');
      setState(() {
        isListening = true;
        liveResponse = '';
        chunkResponse = '';
        widget.ultraCallback(liveResponse, entireResponse, isListening);
      });
      await speech.listen(
        onResult: (result) {
          setState(() {
            final state = result.recognizedWords;
            liveResponse = state;
            if (result.finalResult) {
              chunkResponse = result.recognizedWords;
            }
            widget.ultraCallback(liveResponse, entireResponse, isListening);
          });
        },
      );
    } else {
      debugPrint('Ultra Speech ERROR : Speech recognition not available');
      // Show user-friendly error message
      setState(() {
        isListening = false;
        widget.ultraCallback(
            'Speech recognition not available. Please check microphone permissions.',
            entireResponse,
            isListening);
      });
    }
  }

  void stopListening() {
    print('STOP LISTENING');
    speech.stop();
    setState(() {
      isListening = false;
      entireResponse = '$entireResponse $chunkResponse';
      widget.ultraCallback(liveResponse, entireResponse, isListening);
    });
  }
}
