import 'package:flutter/material.dart';
import 'package:image_fade/image_fade.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Sample images from Wikimedia Commons:
  static const List<String> _imgs = [
    'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Almeida_Júnior_-_Saudade_%28Longing%29_-_Google_Art_Project.jpg/513px-Almeida_Júnior_-_Saudade_%28Longing%29_-_Google_Art_Project.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Rafael_-_Retrato_de_um_Cardeal.jpg/786px-Rafael_-_Retrato_de_um_Cardeal.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f5/James_McNeill_Whistler_-_La_Princesse_du_pays_de_la_porcelaine_-_brighter.jpg/580px-James_McNeill_Whistler_-_La_Princesse_du_pays_de_la_porcelaine_-_brighter.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/0/01/Hans_Holbein_der_Jüngere_-_Der_Kaufmann_Georg_Gisze_-_Google_Art_Project.jpg/897px-Hans_Holbein_der_Jüngere_-_Der_Kaufmann_Georg_Gisze_-_Google_Art_Project.jpg',
    'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Pieter_Bruegel_the_Elder_-_The_Tower_of_Babel_%28Vienna%29_-_Google_Art_Project_-_edited.jpg/1280px-Pieter_Bruegel_the_Elder_-_The_Tower_of_Babel_%28Vienna%29_-_Google_Art_Project_-_edited.jpg',
  ];

  int _counter = 0;
  bool _clear = true;
  bool _error = false;

  void _incrementCounter() {
    setState(() {
      if (_clear || _error) {
        _clear = _error = false;
      } else {
        _counter = (_counter + 1) % _imgs.length;
      }
    });
  }

  void _clearImage() {
    setState(() {
      _clear = true;
      _error = false;
    });
  }

  void _testError() {
    setState(() => _error = true);
  }

  @override
  Widget build(BuildContext context) {
    String? url;
    if (_error) {
      url = 'error.jpg';
    } else if (!_clear) {
      url = _imgs[_counter];
    }

    String title = _error
        ? 'error'
        : _clear
            ? 'placeholder'
            : 'image #$_counter from Wikimedia';

    return Scaffold(
      appBar: AppBar(title: Text('Showing ' + title)),
      body: Stack(children: <Widget>[
        Positioned.fill(
            child: ImageFade(
          // whenever the image changes, it will be loaded, and then faded in:
          image: url == null ? null : NetworkImage(url),

          // slow-ish fade for loaded images:
          duration: const Duration(milliseconds: 900),

          // if the image is loaded synchronously (ex. from memory), fade in faster:
          durationFast: const Duration(milliseconds: 150),

          // supports most properties of Image:
          alignment: Alignment.center,
          fit: BoxFit.cover,

          // shown behind everything:
          placeholder: Container(
            color: const Color(0xFFCFCDCA),
            alignment: Alignment.center,
            child: const Icon(Icons.photo, color: Colors.white30, size: 128.0),
          ),

          // shows progress while loading an image:
          loadingBuilder: (context, progress, chunkEvent) =>
              Center(child: CircularProgressIndicator(value: progress)),

          // displayed when an error occurs:
          errorBuilder: (context, error) => Container(
            color: const Color(0xFF6F6D6A),
            alignment: Alignment.center,
            child:
                const Icon(Icons.warning, color: Colors.black26, size: 128.0),
          ),
        ))
      ]),
      floatingActionButton:
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Next',
          child: const Icon(Icons.navigate_next),
        ),
        const SizedBox(width: 10.0),
        FloatingActionButton(
          onPressed: _clearImage,
          tooltip: 'Clear',
          child: const Icon(Icons.clear),
        ),
        const SizedBox(width: 10.0),
        FloatingActionButton(
          onPressed: _testError,
          tooltip: 'Error',
          child: const Icon(Icons.warning),
        ),
      ]),
    );
  }
}
