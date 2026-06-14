import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';

class WeatherMapModal extends StatefulWidget {
  final double lat;
  final double lon;

  const WeatherMapModal({super.key, required this.lat, required this.lon});

  @override
  State<WeatherMapModal> createState() => _WeatherMapModalState();
}

class _WeatherMapModalState extends State<WeatherMapModal> {
  String _activeFilter = 'precipitation_new';
  final MapController _mapController = MapController();
  final _locationService = LocationService();

  bool _isLoadingLocation = false;
  bool _isLoadingData = false;
  List<Marker> _markers = [];

  final List<Map<String, String>> _filters = [
    {'id': 'precipitation_new', 'name': 'Опади'},
    {'id': 'clouds_new', 'name': 'Хмари'},
    {'id': 'temp_new', 'name': 'Температура'},
    {'id': 'wind_new', 'name': 'Вітер'},
    {'id': 'earthquakes', 'name': 'Землетруси'},
    {'id': 'fires', 'name': 'Пожежі'},
  ];

  @override
  void initState() {
    super.initState();
    _handleFilterChange(_activeFilter);
  }

  void _centerOnCurrentCity() {
    _mapController.move(LatLng(widget.lat, widget.lon), 6.0);
  }

  Future<void> _centerOnGPS() async {
    setState(() => _isLoadingLocation = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      _mapController.move(LatLng(pos.latitude, pos.longitude), 8.0);
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _handleFilterChange(String filterId) async {
    setState(() {
      _activeFilter = filterId;
      _markers = [];
    });

    if (filterId == 'earthquakes') {
      await _fetchEarthquakes();
    } else if (filterId == 'fires') {
      await _fetchFires();
    }
  }

  Future<void> _fetchEarthquakes() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await http.get(Uri.parse(
          'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List features = data['features'];

        final newMarkers = features.map((f) {
          final coords = f['geometry']['coordinates'];
          final mag = f['properties']['mag']?.toDouble() ?? 0.0;

          return Marker(
            point: LatLng(coords[1], coords[0]),
            width: 30,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                color: mag > 5.0 ? Colors.redAccent.withOpacity(0.7) : Colors.orangeAccent.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1),
              ),
              child: Center(
                child: Text(
                  mag.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList();

        if (mounted) setState(() => _markers = newMarkers);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchFires() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await http.get(Uri.parse(
          'https://eonet.gsfc.nasa.gov/api/v3/events?category=wildfires&status=open&days=3'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'];

        final newMarkers = events.map((event) {
          final coords = event['geometries'][0]['coordinates'];
          return Marker(
            point: LatLng(coords[1], coords[0]),
            width: 24,
            height: 24,
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.deepOrangeAccent,
              size: 24,
            ),
          );
        }).toList();

        if (mounted) setState(() => _markers = newMarkers);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    final isWeatherLayer = !_activeFilter.contains('earthquakes') && !_activeFilter.contains('fires');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        color: Colors.blueGrey.shade900,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(widget.lat, widget.lon),
                initialZoom: 4.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cloudy',
                ),
                if (isWeatherLayer)
                  TileLayer(
                    urlTemplate: 'https://tile.openweathermap.org/map/$_activeFilter/{z}/{x}/{y}.png?appid=$apiKey',
                    backgroundColor: Colors.transparent,
                  ),
                if (!isWeatherLayer)
                  MarkerLayer(markers: _markers),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade900.withOpacity(0.7),
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Глобальна карта',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (_isLoadingData)
                                const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = _filters[index];
                              final isActive = _activeFilter == filter['id'];

                              return GestureDetector(
                                onTap: () => _handleFilterChange(filter['id']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.blueAccent : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    filter['name']!,
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'center_city',
                    onPressed: _centerOnCurrentCity,
                    backgroundColor: Colors.blueGrey.shade800,
                    elevation: 0,
                    highlightElevation: 0,
                    child: const Icon(Icons.location_city, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'my_location',
                    onPressed: _centerOnGPS,
                    backgroundColor: Colors.blueAccent,
                    elevation: 0,
                    highlightElevation: 0,
                    child: _isLoadingLocation
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.my_location, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}