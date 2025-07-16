import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSuggestionsVisible = false;
  List<String> _searchHistory = [];
  loc.LocationData? _currentLocation;

  final LatLng _center = const LatLng(25.0340, 121.5645); // Taipei 101

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isSuggestionsVisible = _focusNode.hasFocus;
      });
    });
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onSearch(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(location.latitude, location.longitude),
            zoom: 15.0,
          ),
        ));
        if (!_searchHistory.contains(query)) {
          setState(() {
            _searchHistory.add(query);
            if (_searchHistory.length > 4) {
              _searchHistory.removeAt(0);
            }
          });
        }
      }
    } catch (e) {
      print(e);
    }
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        elevation: 2,
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            myLocationButtonEnabled: false,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
          ),
          if (_isSuggestionsVisible)
            Positioned(
              bottom: 110,
              left: MediaQuery.of(context).size.width * 0.1,
              right: MediaQuery.of(context).size.width * 0.1,
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchHistory.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _searchHistory.length) {
                        return ListTile(
                          leading: const Icon(Icons.my_location),
                          title: const Text('My Current Location'),
                          onTap: () {
                            if (_currentLocation != null) {
                              mapController.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(_currentLocation!.latitude!,
                                        _currentLocation!.longitude!),
                                    zoom: 15.0,
                                  ),
                                ),
                              );
                            }
                            _focusNode.unfocus();
                          },
                        );
                      }
                      final item = _searchHistory.reversed.toList()[index];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(item),
                        onTap: () => _onSearch(item),
                      );
                    },
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 50,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _focusNode,
                      textAlign: TextAlign.center,
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Please Enter your address',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 15.0),
                      ),
                      onSubmitted: _onSearch,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _onSearch(_searchController.text),
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
