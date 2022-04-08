import 'package:geocoding/geocoding.dart';
import 'package:google_place/google_place.dart';
import 'package:provider/provider.dart';
import 'geometry.dart';
import 'location.dart';
import 'place.dart';
import 'blocs/app_blocs.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'geolocation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_api_headers/google_api_headers.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:requests/requests.dart';

const kGoogleApiKey = "AIzaSyArtrJGGyuWasmlZ1rcmovSoCkl7zJWgIE";
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => appbloc(),
      child: MaterialApp(
        title: 'Flutter Google Maps Demo',
        home: MapSample(),
      ),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

final homeScaffoldKey = GlobalKey<ScaffoldState>();
final searchScaffoldKey = GlobalKey<ScaffoldState>();

class MapSampleState extends State<MapSample> {
  var msgController = TextEditingController();

  @override
  void dispose() {
    msgController.dispose();
    super.dispose();
  }

  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  //camera position at start

  var address;
  static String latitude =
      ""; //to declare any variable just statically declare here
  //and use in downward init function and initilize it there simple
  static String longitude = "";
  static Set<Circle> mycircles = Set.from([Circle(circleId: CircleId('1'))]);
  static Marker _kGooglePlexMarker = Marker(markerId: MarkerId('GooglePlex'));
  static Marker _fastMarker = Marker(markerId: MarkerId('fastMarker'));
  //made static because giving initilzer error
  late StreamSubscription locationSubscription;
  late StreamSubscription boundsSubscription;
  final _locationController = TextEditingController();
  static String mysource = "";
  @override
  void initState() {
    super.initState();
    final applicationBloc = Provider.of<appbloc>(context, listen: false);
    locationSubscription =
        applicationBloc.selectedLocation.stream.listen((place) {
      if (place != null) {
        _locationController.text = place.name;
        _goToTheDestination(place);
      } else
        _locationController.text = "";
    });
    getLocation();
  } //to run getlocation when code starts

  getLocation() async {
    var pos = determinePosition(); //if pos is error then
    pos.catchError(print);
    //if determinePOSITION goes in error we will handle in upper else
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    String mapKey = "AIzaSyArtrJGGyuWasmlZ1rcmovSoCkl7zJWgIE";
    //var param = LatLng(position.latitude, position.longitude);
    var karam1 = position.latitude;
    var karam2 = position.longitude;
    String kar1 = karam1.toString();
    String kar2 = karam2.toString();
    String param;
    param = kar1 + "," + kar2;
    String autoCompleteUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$param&key=$mapKey";
    var res = await http.get(Uri.parse(autoCompleteUrl));
    var json = convert.jsonDecode(res.body);
    mysource = json['results'][0]['formatted_address'];
    // print(json['results'][0]['formatted_address'].runtimeType);
    setState(() {
      latitude = '${position.latitude}';
      longitude =
          '${position.longitude}'; //latitude and longitude variables are getting updated here
      final lat = latitude;
      final long = longitude;
      mycircles = Set.from([
        Circle(
          circleId: CircleId('1'),
          center: LatLng(double.parse(lat), double.parse(long)),
          radius: 1000,
        )
      ]);

      _kGooglePlexMarker = Marker(
        markerId: MarkerId('GooglePlex'),
        infoWindow: InfoWindow(title: mysource),
        icon: BitmapDescriptor.defaultMarker,
        position: LatLng(double.parse(latitude), double.parse(longitude)),
      );

      _fastMarker = Marker(
        markerId: MarkerId('Fast_Marker'),
        infoWindow: InfoWindow(title: 'My Destination'),
        icon: BitmapDescriptor.defaultMarker,
        position: LatLng(33.6561535, 73.0135573), //hard coded for fast rn
      );
    });
  }

  static final CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(
          double.parse(latitude),
          double.parse(
              longitude)), //going to that cordinates which were given by my function of geolocation
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    final applicationbloc = Provider.of<appbloc>(context);
    return new Scaffold(
      key: homeScaffoldKey,
      body: Column(children: [
        SizedBox(
          height: 40.0,
        ),
        TextField(
          onChanged: (value) {
            applicationbloc.searchPlaces(value);
          },
          controller: msgController,
          decoration: InputDecoration(
              /* prefixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  /*search it */
                  //search let's just simply use google maps flutter widget
                },
              ),*/ /*
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  /* Clear the search field */
                  msgController.clear();
                  applicationbloc.clearResults();
                },
              ),*/
              hintText: 'Search...',
              border: InputBorder.none),
        ),
        Stack(
          children: [
            Container(
                height: 680,
                child: GoogleMap(
                  onLongPress: addmarker,
                  markers: {_kGooglePlexMarker, _fastMarker},
                  mapType: MapType.normal,
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  myLocationEnabled: true, //for blue dot
                  circles: mycircles,
                )),
            if (applicationbloc.searchResults.length != 0)
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.6),
                  backgroundBlendMode: BlendMode.darken,
                ),
              ),
            if (applicationbloc.searchResults.length != 0)
              Container(
                height: 300,
                child: ListView.builder(
                    itemCount: applicationbloc.searchResults
                        .length, //now search results can be none so
                    itemBuilder: ((context, index) {
                      return ListTile(
                        title: Text(
                          applicationbloc.searchResults[index].description,
                          style: TextStyle(
                              color: Color.fromARGB(255, 253, 253, 253)),
                        ),
                        onTap: () {
                          //make textfields null
                          msgController.clear();
                          applicationbloc.setSelectedLocation(
                              applicationbloc.searchResults[index].placeId);
                        },
                      );
                    })),
              ),
          ],
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheLake,
        label: Text('My Location'),
        icon: Icon(Icons.location_searching),
      ),
    );
  }

  void addmarker(LatLng pos) {
    setState(() {
      _fastMarker = Marker(
        markerId: MarkerId('Fast_Marker'),
        infoWindow: InfoWindow(title: 'My Destination'),
        icon: BitmapDescriptor.defaultMarker,
        position: pos, //hard coded for fast rn
      );
    });
  }

  Future<void> _goToTheLake() async {
    getLocation();
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future<void> _goToTheDestination(Place place) async {
    final GoogleMapController controller = await _controller.future;
    final CameraPosition destination = CameraPosition(
        target:
            LatLng(place.geometry.location.lat, place.geometry.location.lng),
        zoom: 14.0);
    controller.animateCamera(CameraUpdate.newCameraPosition(destination));

    _fastMarker = Marker(
      markerId: MarkerId(place.name),
      infoWindow: InfoWindow(title: place.name),
      icon: BitmapDescriptor.defaultMarker,
      position: LatLng(place.geometry.location.lat,
          place.geometry.location.lng), //hard coded for fast rn
    );
    // so hum screen ko legae +
    //humne udhar marker bh rkhdia
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// WE HAVE DONE GET MY LOCATION TILL HERE

//

// i will be following this : https://www.youtube.com/watch?v=QP4FCi9MgHU
