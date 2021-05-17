import 'dart:html';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Stealth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Stealth'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  final image =
      'https://developers.google.com/maps/documentation/javascript/examples/full/images/beachflag.png';

  final File markerImageFile = await DefaultCacheManager().getSingleFile(image);
  final Uint8List markerImageBytes = await markerImageFile.readAsBytes();

  BitmapDescriptor.fromBytes(markerImageBytes);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static LatLng _initialPosition;
  GoogleMapController _controller;
  Set<Marker> markers = Set();
  MarkerId selectedMarker;
  int _markerIdCounter = 1;
  BitmapDescriptor myPinLocationIcon;

  Position _currentPosition;
  BitmapDescriptor myIcon;
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        _initialPosition = new LatLng(position.latitude, position.longitude);
      });
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    setCustomMapPin();
  }

  void _onMapCreated(GoogleMapController _cntlr) {
    _controller = _cntlr;
    _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target:
                LatLng(_currentPosition.latitude, _currentPosition.longitude),
            zoom: 15),
      ),
    );
  }

  void setCustomMapPin() async {
    myIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5), 'assets/test1.jpg');
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker tappedMarker =
        markers.singleWhere((element) => element.markerId == markerId);
    if (tappedMarker != null) {
      setState(() {
        markers.remove(tappedMarker);
        selectedMarker = markerId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    void _addMarkerLongPressed(latlang) async {
      final int markerCount = markers.length;

      if (markerCount == 5) {
        return;
      }

      final String markerIdVal = 'marker_id_$_markerIdCounter';
      _markerIdCounter++;
      final MarkerId markerId = MarkerId(markerIdVal);

      final Marker marker = Marker(
          markerId: markerId,
          draggable: true,
          onTap: () {
            _onMarkerTapped(markerId);
          },
          position: latlang,
          infoWindow: InfoWindow(
            title: "Pin ${markers.length + 1}",
            snippet: 'I have been here',
          ),
          icon: myIcon,
          visible: true,
          consumeTapEvents: true);

      setState(() {
        markers.add(marker);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialPosition),
                mapType: MapType.normal,
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                compassEnabled: true,
                onLongPress: (latlang) {
                  _addMarkerLongPressed(latlang);
                },
                markers: markers),
            Positioned(
              left: 40,
              bottom: 40,
              child: FloatingActionButton(
                onPressed: () {
                  _addMarkerLongPressed(_initialPosition);
                },
                child: Icon(Icons.pin_drop_outlined),
              ),
            )
          ],
        ),
      ),
    );
  }
}
