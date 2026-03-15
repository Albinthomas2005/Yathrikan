import re

with open(r'lib\screens\shortest_route_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# The broken block starts after 'final toText = ...' and ends just before 'incoming.sort'
# We replace the entire _updateBusList body from after the toText line to before the sort

OLD_BLOCK = r"""
 HEAD
    // The user ONLY wants buses to show up if the search endpoints are exclusively:
    // Koovappally, Kanjirappally, Ponkunnam, Kottayam, Erumely
    const allowedPlaces = ['koovappally', 'kanjirappally', 'ponkunnam', 'kottayam', 'erumely', 'erumely north'];
    
    // We check if either the 'from' or 'to' text (if not empty) matches our allowed places
    final bool isFromValid = fromText.isEmpty || rawFromText.toLowerCase() == 'current location' || allowedPlaces.contains(fromText);
    final bool isToValid = toText.isEmpty || allowedPlaces.contains(toText);

    if (!isFromValid || !isToValid) {
        setState(() {
            _availableBuses = [];
        });
        _busService.setTrackedBuses([]); // clear tracking 
        return;
    }

    // Case-insensitive lookup

    // Case-insensitive lookup for "From" coords
// 47db6fe3c (added live location using iot)
    LatLng? fromCoords;
    for (final entry in BusLocationService.keyPlaces.entries) {
        if (_busService.normalizeLocationName(entry.key) == fromText) {
            fromCoords = entry.value;
            break;
        }
    }
    
    // Fallback if user means "Current Location"
    if (fromCoords == null && (rawFromText.toLowerCase() == "current location" || rawFromText.isEmpty)) {
        fromCoords = _currentLocation;
    }

    final incoming = buses.where((b) {
      if (b.status != 'RUNNING') return false;
       HEAD
      // Filter by direction/route if "To" is specified
      bool matchesRoute = true;
      if (toText.isNotEmpty) {
           const routeOrder = ['erumely', 'erumely north', 'koovappally', 'kanjirappally', 'ponkunnam', 'vazhoor', 'kottayam', 'ettumanoor', 'kuravilangad', 'bharananganam', 'pala'];
           final fi = routeOrder.indexOf(fromText);
           final ti = routeOrder.indexOf(toText);
           
           if (fi != -1 && ti != -1 && fi < ti) {
               matchesRoute = b.routeName.toLowerCase().contains('erumely - kottayam') || 
                              b.routeName.toLowerCase().contains('kottayam - pala') ||
                              b.to.toLowerCase() == toText;
           } else if (fi != -1 && ti != -1 && fi > ti) {
               matchesRoute = b.routeName.toLowerCase().contains('kottayam - erumely') ||
                              b.routeName.toLowerCase().contains('pala - kottayam') ||
                              b.to.toLowerCase() == toText;
           } else {
               matchesRoute = b.to.toLowerCase() == toText || b.routeName.toLowerCase().contains(toText);
           }

      final toLower = toText.trim().toLowerCase();
      final fromLower = fromText.trim().toLowerCase();
      bool matchesRoute = true;
      if (toLower.isNotEmpty) {
           // Direct destination match OR route name contains destination
           matchesRoute = b.to.toLowerCase() == toLower || 
                          b.routeName.toLowerCase().contains(toLower) ||
                          b.routeName.toLowerCase().contains(fromLower);
           
           if (!matchesRoute) {
               // Direction-based matching for main route stops
               if ((fromLower.contains('erumely') && toLower.contains('koovappally')) ||
                   (fromLower.contains('koovappally') && toLower.contains('kottayam')) ||
                   (fromLower.contains('kanjirappally') && toLower.contains('kottayam')) ||
                   (fromLower.contains('ponkunnam') && toLower.contains('kottayam'))) {
                    matchesRoute = b.routeName.contains('Erumely - Kottayam') ||
                                   (b.from.toLowerCase().contains('erumely') && b.to.toLowerCase().contains('kottayam'));
               } else if ((fromLower.contains('kottayam') && toLower.contains('koovappally')) ||
                          (fromLower.contains('koovappally') && toLower.contains('erumely')) ||
                          (fromLower.contains('kottayam') && toLower.contains('kanjirappally')) ||
                          (fromLower.contains('kottayam') && toLower.contains('ponkunnam'))) {
                    matchesRoute = b.routeName.contains('Kottayam - Erumely') ||
                                   (b.from.toLowerCase().contains('kottayam') && b.to.toLowerCase().contains('erumely'));
               } else {
                   // For admin-added buses: match by from/to city names directly
                   matchesRoute = (b.from.toLowerCase().contains(fromLower) || fromLower.isEmpty) &&
                                  (b.to.toLowerCase().contains(toLower) || toLower.isEmpty);
               }
          }
     //47db6fe3c (added live location using iot)
      }
      
      if (!matchesRoute) return false;

      // Check if incoming relative to the "From" location
      return _busService.isIncoming(b, relativeTo: fromCoords);
    }).toList();"""

NEW_BLOCK = """
    const allowedPlaces = ['koovappally', 'kanjirappally', 'ponkunnam', 'kottayam', 'erumely', 'erumely north'];
    final bool isFromValid = fromText.isEmpty || rawFromText.toLowerCase() == 'current location' || allowedPlaces.contains(fromText);
    final bool isToValid = toText.isEmpty || allowedPlaces.contains(toText);

    if (!isFromValid || !isToValid) {
      setState(() { _availableBuses = []; });
      _busService.setTrackedBuses([]);
      return;
    }

    LatLng? fromCoords;
    for (final entry in BusLocationService.keyPlaces.entries) {
      if (_busService.normalizeLocationName(entry.key) == fromText) {
        fromCoords = entry.value;
        break;
      }
    }
    if (fromCoords == null && (rawFromText.toLowerCase() == 'current location' || rawFromText.isEmpty)) {
      fromCoords = _currentLocation;
    }

    final incoming = buses.where((b) {
      if (b.status != 'RUNNING') return false;

      final toLower = toText.trim().toLowerCase();
      final fromLower = fromText.trim().toLowerCase();
      bool matchesRoute = true;

      if (toLower.isNotEmpty) {
        matchesRoute = b.to.toLowerCase() == toLower ||
                       b.routeName.toLowerCase().contains(toLower) ||
                       b.routeName.toLowerCase().contains(fromLower);

        if (!matchesRoute) {
          if ((fromLower.contains('erumely') && toLower.contains('koovappally')) ||
              (fromLower.contains('koovappally') && toLower.contains('kottayam')) ||
              (fromLower.contains('kanjirappally') && toLower.contains('kottayam')) ||
              (fromLower.contains('ponkunnam') && toLower.contains('kottayam'))) {
            matchesRoute = b.routeName.contains('Erumely - Kottayam') ||
                           (b.from.toLowerCase().contains('erumely') && b.to.toLowerCase().contains('kottayam'));
          } else if ((fromLower.contains('kottayam') && toLower.contains('koovappally')) ||
                     (fromLower.contains('koovappally') && toLower.contains('erumely')) ||
                     (fromLower.contains('kottayam') && toLower.contains('kanjirappally')) ||
                     (fromLower.contains('kottayam') && toLower.contains('ponkunnam'))) {
            matchesRoute = b.routeName.contains('Kottayam - Erumely') ||
                           (b.from.toLowerCase().contains('kottayam') && b.to.toLowerCase().contains('erumely'));
          } else {
            matchesRoute = (b.from.toLowerCase().contains(fromLower) || fromLower.isEmpty) &&
                           (b.to.toLowerCase().contains(toLower) || toLower.isEmpty);
          }
        }
      }

      if (!matchesRoute) return false;
      return _busService.isIncoming(b, relativeTo: fromCoords);
    }).toList();"""

if OLD_BLOCK in content:
    content = content.replace(OLD_BLOCK, NEW_BLOCK, 1)
    with open(r'lib\screens\shortest_route_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS: Block replaced")
else:
    print("ERROR: Old block not found - checking for HEAD markers...")
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'HEAD' in line and i > 270 and i < 330:
            print(f"  Line {i+1}: {repr(line)}")
