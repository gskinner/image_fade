import 'package:flutter/material.dart';
import 'package:image_fade/image_fade.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

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
      if (_clear || _error) { _clear = _error = false; }
      else { _counter = (_counter+1)%_imgs.length; }
    });
  }

  void _clearImage() {
    setState(() {
      _clear = true;
      _error = false;
    });
  }

  void _testError() {
    setState(() {
      _error = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider image;
    if (_error) { image = NetworkImage('error.jpg'); }
    else if (!_clear) { image = NetworkImage(_imgs[_counter]); }

    return Scaffold(
      appBar: AppBar(
        title: Text('Showing ' + (_error ? 'error' : _clear ? 'placeholder' : 'image #$_counter from Wikimedia')),
      ),

      body: Stack(children: <Widget>[
        Positioned.fill(child: 
          ImageFade(
            image: image,
            placeholder: Container(
              color: Color(0xFFCFCDCA),
              child: Center(child: Icon(Icons.photo, color: Colors.white30, size: 128.0,)),
            ),
            alignment: Alignment.center,
            fit: BoxFit.cover,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent event) {
              if (event == null) { return child; }
              return Center(
                child: CircularProgressIndicator(
                  value: event.expectedTotalBytes == null ? 0.0 : event.cumulativeBytesLoaded / event.expectedTotalBytes
                ),
              );
            },
            errorBuilder: (BuildContext context, Widget child, dynamic exception) {
              return Container(
                color: Color(0xFF6F6D6A),
                child: Center(child: Icon(Icons.warning, color: Colors.black26, size: 128.0)),
              );
            },
          )
        )
      ]),

      floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(
          onPressed: _incrementCounter,
          tooltip: 'Next',
          child: Icon(Icons.navigate_next),
        ),
        SizedBox(width:10.0),
        FloatingActionButton(
          onPressed: _clearImage,
          tooltip: 'Clear',
          child: Icon(Icons.clear),
        ),
        SizedBox(width:10.0),
        FloatingActionButton(
          onPressed: _testError,
          tooltip: 'Error',
          child: Icon(Icons.warning),
        ),
      ]),
    );
  }
}
