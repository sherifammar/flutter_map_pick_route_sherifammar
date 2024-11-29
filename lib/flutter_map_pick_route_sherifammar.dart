
library flutter_map_pick_route_sherifammar;

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:flutter_map_pick_route_sherifammar/wide_button.dart';
import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';


class FlutterMapSearchAndPinkRoute extends StatefulWidget {

  final Color buttonColor;
  final Color buttonTextColor;


  final String buttonText;
  final double buttonHeight;
  final double buttonWidth;
  final TextStyle buttonTextStyle;
  final String baseUri;

  final String hintText;
  final String hintText1;

  final String orsApiKey;
  final double latidedCurrent;
  final double longtideCurrent;

  const FlutterMapSearchAndPinkRoute({
    Key? key,
    this.buttonColor = Colors.blue,
 

    this.hintText = "where you are your location",
    this.hintText1 = "where you want to go",
    this.buttonTextStyle = const TextStyle(
        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    this.buttonTextColor = Colors.white,
    this.buttonText = "draw route",
    this.buttonHeight = 50,
    this.buttonWidth = 200,
    this.baseUri = 'https://nominatim.openstreetmap.org',

  

    required this.orsApiKey,
    required this.latidedCurrent,
    required this.longtideCurrent,
  }) : super(key: key);

  @override
  State<FlutterMapSearchAndPinkRoute> createState() =>
      _FlutterMapSearchAndPinkRouteState();
}

class _FlutterMapSearchAndPinkRouteState
    extends State<FlutterMapSearchAndPinkRoute> {
  MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchController1 = TextEditingController();

  final FocusNode _focusNode = FocusNode();
  List<OSMdata> _options = <OSMdata>[];
  Timer? _debounce;

  final FocusNode _focusNode1 = FocusNode();
  List<OSMdata> _options1 = <OSMdata>[];
  Timer? _debounce1;

  var client = http.Client();
  late Future<Position?> latlongFuture;

  double? lat; // var used by addmarker
  double? long;

  double? lat1; // var used by addmarker
  double? long1;
  // LocationData? currentLocation;
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  double? distanceInMeters = 0.0;

  getDistance(
      double startlat, double startlong, double finallat, double finallong) {
    double distanceInMeters =
        Geolocator.distanceBetween(startlat, startlong, finallat, finallong);
    // print(
    //     " ===== distanceInMeters >>. distanceInMeters *** $distanceInMeters ======= ");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Distance : $distanceInMeters /Meters",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
    return distanceInMeters;
  }

  Future<Position?> getCurrentPosLatLong() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();

    /// do not have location permission
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
      return await getPosition(locationPermission);
    }

    /// have location permission
    Position position = await Geolocator.getCurrentPosition();

    return position;
  }

  Future<Position?> getPosition(LocationPermission locationPermission) async {
    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      return null;
    }
    Position position = await Geolocator.getCurrentPosition();

    return position;
  }

  getRoute(double endsearchlat, double endsearchlong, double endsearchlat1,
      double endsearchlong1) async {
    LatLng points = LatLng(endsearchlat, endsearchlong);
    LatLng points1 = LatLng(endsearchlat1, endsearchlong1);
    markers.clear();

    // print(
    //     " ===== polyline >>. newlat *** ${points.latitude}  ++++++//+++++  newlong ***${points.longitude} =======  endlat *** ${points1.latitude}  ++++++//+++++  endlong ***${points1.longitude} ======= ");

    final response = await http.get(
      Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=${widget.orsApiKey}&start=${points.longitude},${points.latitude}&end=${points1.longitude},${points1.latitude}'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> coords =
          data['features'][0]['geometry']['coordinates'];

      routePoints = coords.map((coord) => LatLng(coord[1], coord[0])).toList();

      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: points,
          builder: (ctx) =>
              const Icon(Icons.location_pin, color: Colors.blue, size: 40.0),
        ),
      );
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: points1,
          builder: (ctx) =>
              const Icon(Icons.location_pin, color: Colors.red, size: 40.0),
        ),
      );

      // print(
      //     " 222222 ===== polyline >>. newlat *** ${points.latitude}  ++++++//+++++  newlong ***${points.longitude} =======  endlat *** ${points1.latitude}  ++++++//+++++  endlong ***${points1.longitude} ======= ");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to fetch route",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    // }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // String? _autocompleteSelection;
    OutlineInputBorder inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: widget.buttonColor),
    );
    OutlineInputBorder inputFocusBorder = OutlineInputBorder(
      borderSide: BorderSide(color: widget.buttonColor, width: 3.0),
    );
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                  center: LatLng(widget.latidedCurrent, widget.longtideCurrent),
                  zoom: 15.0,
                  maxZoom: 18,
                  minZoom: 6),
              mapController: _mapController,
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: markers,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
   
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                children: [
                  TextFormField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: inputBorder,
                        focusedBorder: inputFocusBorder,
                      ),
                      onChanged: (String value) {
                        if (_debounce?.isActive ?? false) {
                          _debounce?.cancel();
                        }

                        _debounce =
                            Timer(const Duration(milliseconds: 1000), () async {
                          if (kDebugMode) {
                            print(value);
                          }
                          var client = http.Client();
                          try {
                            String url =
                                '${widget.baseUri}/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
                            if (kDebugMode) {
                              print(url);
                            }
                            var response = await client.get(Uri.parse(url));
                            // var response = await client.post(Uri.parse(url));
                            var decodedResponse =
                                jsonDecode(utf8.decode(response.bodyBytes))
                                    as List<dynamic>;
                            if (kDebugMode) {
                              print(decodedResponse);
                            }
                            _options = decodedResponse
                                .map(
                                  (e) => OSMdata(
                                    displayname: e['display_name'],
                                    lat: double.parse(e['lat']),
                                    lon: double.parse(e['lon']),
                                  ),
                                )
                                .toList();

                            setState(() {});
                          } finally {
                            client.close();
                          }

                          setState(() {});
                        });
                      }),
                         StatefulBuilder(
                    builder: ((context, setState) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _options.length > 5 ? 5 : _options.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_options[index].displayname),
                            subtitle: Text(
                                '${_options[index].lat},${_options[index].lon}'),
                            onTap: () {
                              _searchController.text =
                                  _options[index].displayname;

                              lat = _options[index].lat;
                              long = _options[index].lon;
                              // print("position => $lat === $long ");
                              _focusNode.unfocus();
                              _options.clear();
                              setState(() {});
                            },
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                      controller: _searchController1,
                      focusNode: _focusNode1,
                      decoration: InputDecoration(
                        hintText: widget.hintText1,
                        border: inputBorder,
                        focusedBorder: inputFocusBorder,
                      ),
                      onChanged: (String value) {
                        if (_debounce1?.isActive ?? false) {
                          _debounce1?.cancel();
                        }

                        _debounce1 =
                            Timer(const Duration(milliseconds: 1000), () async {
                          if (kDebugMode) {
                            print(value);
                          }
                          var client = http.Client();
                          try {
                            String url =
                                '${widget.baseUri}/search?q=$value&format=json&polygon_geojson=1&addressdetails=1';
                            if (kDebugMode) {
                              print(url);
                            }
                            var response = await client.get(Uri.parse(url));
                            // var response = await client.post(Uri.parse(url));
                            var decodedResponse =
                                jsonDecode(utf8.decode(response.bodyBytes))
                                    as List<dynamic>;
                            if (kDebugMode) {
                              print(decodedResponse);
                            }
                            _options1 = decodedResponse
                                .map(
                                  (e) => OSMdata(
                                    displayname: e['display_name'],
                                    lat: double.parse(e['lat']),
                                    lon: double.parse(e['lon']),
                                  ),
                                )
                                .toList();

                            setState(() {});
                          } finally {
                            client.close();
                          }

                          setState(() {});
                        });
                      }),
               
                  StatefulBuilder(
                    builder: ((context, setState) {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _options1.length > 5 ? 5 : _options1.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_options1[index].displayname),
                            subtitle: Text(
                                '${_options1[index].lat},${_options1[index].lon}'),
                            onTap: () {
                              _searchController1.text =
                                  _options1[index].displayname;

                              lat1 = _options1[index].lat;
                              long1 = _options1[index].lon;
                         

                              _focusNode1.unfocus();
                              _options1.clear();
                              setState(() {});
                            },
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: WideButton(
                  widget.buttonText,
                  textStyle: widget.buttonTextStyle,
                  height: widget.buttonHeight,
                  width: widget.buttonWidth,
                  onPressed: () async {
                
                    await getRoute(lat!, long!, lat1!, long1!);
                    _mapController.move(LatLng(lat!, long!), 15.0);
                    getDistance(lat!, long!, lat1!, long1!);
                    setState(() {});
                  },
                  backgroundColor: widget.buttonColor,
                  foregroundColor: widget.buttonTextColor,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class OSMdata {
  final String displayname;
  final double lat;
  final double lon;
  OSMdata({required this.displayname, required this.lat, required this.lon});
  @override
  String toString() {
    return '$displayname, $lat, $lon';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is OSMdata && other.displayname == displayname;
  }

  @override
  int get hashCode => Object.hash(displayname, lat, lon);
}

class LatLong {
  final double latitude;
  final double longitude;
  const LatLong(this.latitude, this.longitude);
}

class PickedData {
  final LatLong latLong;
  final String addressName;
  final Map<String, dynamic> address;

  PickedData(this.latLong, this.addressName, this.address);
}
