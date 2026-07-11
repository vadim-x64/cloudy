import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import '../services/weather_service.dart';

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
  final _weatherService = WeatherService();

  bool _isLoadingLocation = false;
  bool _isLoadingData = false;
  List<Marker> _markers = [];

  LatLng? _tappedPoint;
  Map<String, dynamic>? _tappedLocationInfo;
  bool _isLoadingTappedLocation = false;

  final List<Map<String, String>> _filters = [
    {'id': 'precipitation_new', 'name': 'Опади'},
    {'id': 'clouds_new', 'name': 'Хмари'},
    {'id': 'temp_new', 'name': 'Температура'},
    {'id': 'wind_new', 'name': 'Вітер'},
    {'id': 'pressure_new', 'name': 'Тиск'},
    {'id': 'earthquakes', 'name': 'Землетруси'},
    {'id': 'fires', 'name': 'Пожежі'},
    {'id': 'storms', 'name': 'Грози'},
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
    } else if (filterId == 'storms') {
      await _fetchStorms();
    }
  }

  Future<void> _fetchEarthquakes() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson',
        ),
      );

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
                color: mag > 5.0
                    ? Colors.redAccent.withOpacity(0.7)
                    : Colors.orangeAccent.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white54, width: 1),
              ),
              child: Center(
                child: Text(
                  mag.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
      final response = await http.get(
        Uri.parse(
          'https://eonet.gsfc.nasa.gov/api/v3/events?category=wildfires&status=open&days=7',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'];

        final newMarkers = <Marker>[];
        for (var event in events) {
          if (event['geometry'] != null && event['geometry'].isNotEmpty) {
            final geo = event['geometry'][0];
            double lat = 0.0;
            double lon = 0.0;

            if (geo['type'] == 'Point') {
              lon = geo['coordinates'][0];
              lat = geo['coordinates'][1];
            } else if (geo['type'] == 'Polygon') {
              lon = geo['coordinates'][0][0][0];
              lat = geo['coordinates'][0][0][1];
            }

            newMarkers.add(
              Marker(
                point: LatLng(lat, lon),
                width: 24,
                height: 24,
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.deepOrangeAccent,
                  size: 24,
                ),
              ),
            );
          }
        }
        if (mounted) setState(() => _markers = newMarkers);
      }
    } catch (e) {
      debugPrint('Fires fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _fetchStorms() async {
    setState(() => _isLoadingData = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://eonet.gsfc.nasa.gov/api/v3/events?category=severeStorms&status=open&days=14',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List events = data['events'];

        final newMarkers = <Marker>[];
        for (var event in events) {
          if (event['geometry'] != null && event['geometry'].isNotEmpty) {
            final geo = event['geometry'][0];
            double lat = 0.0;
            double lon = 0.0;

            if (geo['type'] == 'Point') {
              lon = geo['coordinates'][0];
              lat = geo['coordinates'][1];
            } else if (geo['type'] == 'Polygon') {
              lon = geo['coordinates'][0][0][0];
              lat = geo['coordinates'][0][0][1];
            }

            newMarkers.add(
              Marker(
                point: LatLng(lat, lon),
                width: 28,
                height: 28,
                child: const Icon(
                  Icons.thunderstorm,
                  color: Colors.yellowAccent,
                  size: 28,
                ),
              ),
            );
          }
        }
        if (mounted) setState(() => _markers = newMarkers);
      }
    } catch (e) {
      debugPrint('Storms fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _tappedPoint = point;
      _isLoadingTappedLocation = true;
      _tappedLocationInfo = null;
    });

    try {
      final weather = await _weatherService.fetchWeatherByCoordinates(
        point.latitude,
        point.longitude,
      );
      if (mounted) {
        setState(() {
          _tappedLocationInfo = {
            'lat': point.latitude,
            'lon': point.longitude,
            'name': weather.cityName,
            'temp': weather.temperature,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tappedLocationInfo = {
            'lat': point.latitude,
            'lon': point.longitude,
            'name': 'Невідоме місце',
            'temp': null,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTappedLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    final isWeatherLayer = [
      'precipitation_new',
      'clouds_new',
      'temp_new',
      'wind_new',
      'pressure_new',
    ].contains(_activeFilter);

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
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cloudy',
                ),
                if (isWeatherLayer)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openweathermap.org/map/$_activeFilter/{z}/{x}/{y}.png?appid=$apiKey',
                    backgroundColor: Colors.transparent,
                  ),
                if (!isWeatherLayer) MarkerLayer(markers: _markers),

                if (_tappedPoint != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _tappedPoint!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
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
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Глобальна карта',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isLoadingData)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                    strokeWidth: 2,
                                  ),
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final filter = _filters[index];
                              final isActive = _activeFilter == filter['id'];

                              return GestureDetector(
                                onTap: () => _handleFilterChange(filter['id']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.blueAccent
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    filter['name']!,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
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

            if (_isLoadingTappedLocation || _tappedLocationInfo != null)
              Positioned(
                bottom: 30,
                left: 16,
                right: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade900.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: _isLoadingTappedLocation
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Отримання даних...',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _tappedLocationInfo!['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Шир: ${_tappedLocationInfo!['lat'].toStringAsFixed(4)}, Довг: ${_tappedLocationInfo!['lon'].toStringAsFixed(4)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_tappedLocationInfo!['temp'] != null)
                                  Text(
                                    '${_tappedLocationInfo!['temp'].round()}°C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _tappedPoint = null;
                                      _tappedLocationInfo = null;
                                    });
                                  },
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
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
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
