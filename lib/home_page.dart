import 'package:flutter/material.dart';
import 'package:imgsrc/gallery_repository.dart';
import 'package:imgsrc/model/gallery_item.dart';
import 'package:imgsrc/model/gallery_models.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_view/photo_view.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GallerySection _currentSection = GallerySection.hot;
  GallerySort _currentSort = GallerySort.viral;
  GalleryWindow _currentWindow = GalleryWindow.all;
  int _currentPage = 1;
  int _currentPosition = 0;

  Map<int, VideoPlayerController> _controllers = new Map();
  List<GalleryItem> _galleryItems = new List<GalleryItem>();

  void _loadGalleryItems() {
    GalleryRepository repostiory = new GalleryRepository();
    repostiory
        .getItems(_currentSection, _currentSort, _currentWindow, _currentPage)
        .then((it) {
      setState(() {
        if (it.isOk()) {
          _galleryItems.addAll(it.body);
        }
      });
    });
  }

  void _loadNextPage() {
    _currentPage++;
    _loadGalleryItems();
  }

//  void _reloadGalleryFromSideMenu() {
//    //todo: diff selections to determine if should reset or not
//    _currentPage = 0;
//    _galleryItems = new List();
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      drawer: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 120, 0),
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.green),
                child: Text("eggman87"),
              ),
              Row(
                children: <Widget>[
                  Visibility(
                      visible: _galleryItems.length > 0,
                      child: Text(
                          "  Currently viewing ${_currentPosition + 1}/${_galleryItems.length}"))
                ],
              ),
              ListTile(
                title: Text(
                  "SECTION",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Row(
                children: <Widget>[
                  Spacer(),
                  Text(
                    "hot",
                    style:
                        _selectableStyle(_currentSection == GallerySection.hot),
                  ),
                  Spacer(),
                  Text(
                    "top",
                    style:
                        _selectableStyle(_currentSection == GallerySection.top),
                  ),
                  Spacer(),
                  Text(
                    "User",
                    style: _selectableStyle(
                        _currentSection == GallerySection.user),
                  ),
                  Spacer(),
                ],
              ),
              ListTile(
                title: Text(
                  "SORT",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Row(
                children: <Widget>[
                  Spacer(),
                  Text("viral"),
                  Spacer(),
                  Text("top"),
                  Spacer(),
                  Text("time"),
                  Spacer(),
                  Text("rising"),
                  Spacer(),
                ],
              ),
            ],
          )),
      body: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    _title(),
                    maxLines: 6,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: _pageView(),
                )
              ],
            ),
          )),
      floatingActionButton: Builder(builder: (BuildContext context) {
        return FloatingActionButton(
          onPressed: () => this._onAddTapped(context),
          tooltip: 'Upload Image',
          child: Icon(Icons.add),
        );
      }),
      bottomNavigationBar: BottomNavigationBar(items: [
        BottomNavigationBarItem(
            icon: new Icon(Icons.album), title: Text("Gallery")),
        BottomNavigationBarItem(
            icon: new Icon(Icons.photo), title: Text("My Saus")),
        BottomNavigationBarItem(
            icon: new Icon(Icons.person), title: Text("Social Saus"))
      ]),
    );
  }

  TextStyle _selectableStyle(bool isSelected) {
    if (isSelected) {
      return TextStyle(color: Colors.green);
    } else {
      return TextStyle(color: Colors.black);
    }
  }

  String _title() {
    if (_galleryItems.length > 0) {
      return _galleryItems[_currentPosition].title;
    }
    return "";
  }

  PageView _pageView() {
    return PageView.builder(
      pageSnapping: true,
      itemBuilder: (context, position) {
        String imageUrl = _galleryItems[position].pageUrl();

        if (imageUrl.contains(".mp4")) {
          VideoPlayer player;
          VideoPlayerController controller = _controllers[position];

          if (controller == null) {
            VideoPlayerController controller =
                VideoPlayerController.network(imageUrl);
            _controllers[position] = controller;

            player = VideoPlayer(controller);
            controller.setLooping(true);
            controller.setVolume(0);

            controller.initialize().then((_) {
              controller.play();
            });
          } else {
            player = VideoPlayer(controller);
          }

          return player;
        } else {
          return PhotoView(imageProvider: NetworkImage(imageUrl));
        }
      },
      itemCount: _galleryItems.length,
      onPageChanged: _onPageChanged,
    );
  }

  void _onAddTapped(BuildContext context) {
    final snackBar = SnackBar(content: Text('Add image is under construction'));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void _onPageChanged(int position) {
    setState(() {
      _currentPosition = position;
    });
    if (position == _galleryItems.length) {
      _loadNextPage();
    }

    _controllers.forEach((key, controller) {
      if (key == position) {
        controller.play();
      }
      if (position - key > 4 || key - position > 4) {
        //indicates this controller is for a video > 4 pages away
        controller.dispose();
        _controllers.remove(key);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _loadGalleryItems();
  }
}
