import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayer/audioplayer.dart';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_notifications/local_notifications.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'RadioMix',
      theme: new ThemeData(),
      home: new MyHomePage(title: 'RadioMix'),
    );
  }

}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

enum PlayerState { stopped, playing, paused }

class _MyHomePageState extends State<MyHomePage> {
  FlutterSecureStorage _storage = new FlutterSecureStorage();
  bool loading = true;
  bool refreshing = false;
  bool playing = false;
  String audioId = "";
  String currentUrl = "";
  String audioName = "";
  int currentIndex = 0;
  bool finished = false;
  bool isFavorite = false;
  var allData = [];
  var favoriteItems = [];
  List<Widget> listArray = [];
  List<String> fav = [];
  AudioPlayer audioPlayer;
  PlayerState playerState = PlayerState.stopped;
  static const AndroidNotificationChannel channel = const AndroidNotificationChannel(
    id: 'default_notification11',
    name: 'Radio',
    description: 'Radio',
    importance: AndroidNotificationChannelImportance.DEFAULT,
    vibratePattern: AndroidVibratePatterns.NONE,
  );

  @override
  void initState() {
    super.initState();
    audioPlayer = new AudioPlayer();
  }


  void getRadioList() async {
    var data = await rootBundle.loadString('assets/res/data.json');
    allData = json.decode(data);
    currentUrl = allData[0]["stream"];
    audioId = allData[0]["id"];
    audioName = allData[0]["name"];
    await getFav();
    renderItems();
    setState(() {
      loading = false;
    });
  }

  Future<String> read(key) async {
    String value = await _storage.read(key: key);
    return value;
  }

  Future write(key, value) async {
    _storage.write(key: key, value: value);
  }

  Future delete(key) async {
    await _storage.delete(key: key);
  }

  addFav(key, value) async {
    var isFav = await read(key);
    if (isFav != null) {
      await delete(key);
    } else {
      await write(key, value);
    }
    await getFav();
    renderItems();
    setState(() {
      refreshing = true;
    });
    refreshing = false;
  }

  getFav() async {
    fav = [];
    favoriteItems = [];
    for (var value in allData) {
      var isFav = await read(value["id"]);
      if (isFav != null) {
        fav.add(value["id"]);
        favoriteItems.add(value);
      }
    }
  }

  showHideFav() async {

    isFavorite = !isFavorite;
    renderItems();

    setState(() {
      refreshing = true;
    });
    refreshing = false;
  }


  playPause(String url, String id) async {
    audioPlayer.stop();
    audioName = allData[this.currentIndex]["name"];
    print(currentIndex);
    print(audioName);
    if (audioId == id && playing) {
      audioPlayer.stop();
      playing = false;
      setState(() {
        playerState = PlayerState.stopped;
        playing = false;
      });
    } else {
      audioId = id;
      currentUrl = url;
      final result = await audioPlayer.play(url);
        setState(() {
          playerState = PlayerState.playing;
          playing = true;
        });

    }
    renderItems();
  }

  renderItems() {
    listArray = [];
    var data = [];
    if (isFavorite) {
      data = favoriteItems;
    } else {
      data = allData;
    }
    if(data.length==0) listArray.add(new Container(
      child:new Text(' \n '+' '+"You have no favorite radio stations ;)",


        style: new TextStyle(color: new Color.fromARGB(-1, 175, 174, 251), fontSize:20.0, fontWeight: FontWeight.bold,),
        textAlign: TextAlign.left,

      ) ,

    ) );


    for (var i = 0; i < data.length; i++) {
      listArray.add(new ListTile(
        leading: new CircleAvatar(
          child: new Text(
              data[i]["name"].toString().substring(0, 2).toUpperCase(),
              style: new TextStyle(color: Colors.white)),
          backgroundColor: new Color.fromARGB(-1, 175, 174, 251),
        ),
        title: new Text(data[i]["name"],
          //  style: new TextStyle(color:Color.fromARGB (-1, 87,	87, 125) )),
        ),
        subtitle: new Text(data[i]["Genre"],  style: new TextStyle(color:Color.fromARGB (-1, 191,	190, 251), fontStyle: FontStyle.italic )),


        trailing: new Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              new Container(
                  child:data[i]["id"] == audioId && playing
                      ? new Icon(Icons.play_circle_filled,
                      color: new Color.fromARGB(-1, 175, 174, 251))
                      : null
              ),
              new Container(
                // padding: new EdgeInsets.all(10.0),
                child:new IconButton(
                  padding: new EdgeInsets.all(0.0),
                  iconSize: 35.0,
                  icon: fav.contains(data[i]["id"])
                      ? new Icon(Icons.favorite,
                      color: new Color.fromARGB(-1, 175, 174, 251))// #AFAEFB
                      : new Icon(Icons.favorite_border,
                      color: new Color.fromARGB(-1, 175, 174, 251)),
                  onPressed: () {
                    addFav(data[i]["id"], data[i]["stream"]);
                  },
                ),
              ),

            ]
//     children:<Widget>[new Row( mainAxisAlignment: MainAxisAlignment.end,
//
//       children: [
//         new Container(
//           child:data[i]["id"] == audioId && playing
//               ? new Icon(Icons.play_circle_filled,
//               color: new Color.fromARGB(-1, 175, 174, 251))
//               : new Icon(Icons.adjust,
//               color: new Color.fromARGB(-1, 175, 174, 500)),
//         ),
//         new Container(
//           // padding: new EdgeInsets.all(10.0),
//           child:new IconButton(
//             padding: new EdgeInsets.all(0.0),
//             iconSize: 35.0,
//             icon: fav.contains(data[i]["id"])
//                 ? new Icon(Icons.favorite,
//                 color: new Color.fromARGB(-1, 175, 174, 251))// #AFAEFB
//                 : new Icon(Icons.favorite_border,
//                 color: new Color.fromARGB(-1, 175, 174, 251)),
//             onPressed: () {
//               addFav(data[i]["id"], data[i]["stream"]);
//             },
//           ),
//         ),
//
//       ],
//     ),]
        ) ,


        onTap: () {
          currentIndex = i;
          playPause(data[i]["stream"], data[i]["id"]);
        },


      ));
      listArray.add(new Divider(
          indent: 20.0, color: new Color.fromARGB(-1, 175, 174, 251)));
    }
  }

  playNext() {
    if (this.currentIndex + 1 > allData.length - 1) {
      this.currentIndex = 0;
    } else {
      this.currentIndex = this.currentIndex + 1;
    }
    this.playPause(
        allData[this.currentIndex]["stream"], allData[this.currentIndex]["id"]);
  }

  playPrevious() {
    if (this.currentIndex - 1 < 0) {
      this.currentIndex = allData.length - 1;
    } else {
      this.currentIndex = this.currentIndex - 1;
    }
    this.playPause(
        allData[this.currentIndex]["stream"], allData[this.currentIndex]["id"]);
  }

  static MediaQueryData of(BuildContext context, {bool nullOk: false}) {
    assert(context != null);
    assert(nullOk != null);
    final MediaQuery query = context.inheritFromWidgetOfExactType(MediaQuery);
    if (query != null) return query.data;
    if (nullOk) return null;
    throw new FlutterError(
        'MediaQuery.of() called with a context that does not contain a MediaQuery.\n'
            'No MediaQuery ancestor could be found starting from the context that was passed '
            'to MediaQuery.of(). This can happen because you do not have a WidgetsApp or '
            'MaterialApp widget (those widgets introduce a MediaQuery), or it can happen '
            'if the context you use comes from a widget above those widgets.\n'
            'The context used was:\n'
            '  $context');
  }

  @override
  Widget build(BuildContext context) {
    if (loading) getRadioList();
    return new Scaffold(
        appBar: new AppBar(
            backgroundColor: new Color.fromARGB(-1, 175, 174, 251),
            title: new Text(widget.title),
            actions: <Widget>[
              new IconButton(
                // action button
                icon: new Icon(Icons.favorite),
                onPressed: () async {
                  await showHideFav();
                },
              ),
            ]),
        body: new ListView(
          children: loading ? [] : listArray,
        ),
        bottomNavigationBar: new Container(
          decoration: new BoxDecoration(
              color: new Color.fromARGB(-1, 237, 239, 255),
              boxShadow: [
                new BoxShadow(
                  color: new Color.fromARGB(-1, 175, 174, 251),
                  blurRadius: 3.0,
                ),
              ]),
          height: 60.0,
          padding: new EdgeInsets.all(10.0),
          child: new Center(
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      new Container(
                        child: new Text(audioName,
                            maxLines: 1,
                            textAlign: TextAlign.left,
                            style: new TextStyle(
                                fontWeight: FontWeight.bold,
                                inherit: true,
                                fontSize: 17.0,
                                color: new Color.fromARGB(-1, 140, 139, 200))),
                      ),
                    ],
                  ),
                ),
                new Divider(
                    indent: 20.0, color: new Color.fromARGB(-1, 175, 174, 251)),
                new IconButton(
                  padding: new EdgeInsets.all(0.0),
                  iconSize: 35.0,
                  icon: new Icon(Icons.skip_previous,
                      color: new Color.fromARGB(-1, 175, 174, 251)),
                  onPressed: () {
                    playPrevious();
                  },
                ),
                new IconButton(
                  padding: new EdgeInsets.all(0.0),
                  iconSize: 35.0,
                  icon: playing
                      ? new Icon(Icons.pause_circle_filled,
                      color: new Color.fromARGB(-1, 175, 174, 251))
                      : new Icon(Icons.play_circle_filled,
                      color: new Color.fromARGB(-1, 175, 174, 251)),
                  onPressed: () {
                    playPause(currentUrl, audioId);
                  },
                ),
                new IconButton(
                  padding: new EdgeInsets.all(0.0),
                  iconSize: 35.0,
                  icon: new Icon(Icons.skip_next,
                      color: new Color.fromARGB(-1, 175, 174, 251)),
                  onPressed: () {
                    playNext();
                  },
                ),
              ],
            ),
          ),
        ));
  }
}
