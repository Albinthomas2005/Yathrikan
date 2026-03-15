import sys

with open('lib/screens/shortest_route_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

out = []
in_update_bus_list = False
for line in lines:
    if line.startswith('  void _updateBusList(List<LiveBus> buses) {'):
        in_update_bus_list = True
        
        # INSERT THE CORRECT FUNCTION
        out.append('  void _updateBusList(List<LiveBus> buses) {\n')
        out.append('    final rawFromText = _fromController.text.trim();\n')
        out.append('    final rawToText = _toController.text.trim();\n')
        out.append('    final fromText = _busService.normalizeLocationName(rawFromText);\n')
        out.append('    final toText = _busService.normalizeLocationName(rawToText);\n')
        out.append('    const allowedPlaces = ["koovappally", "kanjirappally", "ponkunnam", "kottayam", "erumely", "erumely north"];\n')
        out.append('    final bool isFromValid = fromText.isEmpty || rawFromText.toLowerCase() == "current location" || allowedPlaces.contains(fromText);\n')
        out.append('    final bool isToValid = toText.isEmpty || allowedPlaces.contains(toText);\n')
        out.append('    if (!isFromValid || !isToValid) {\n')
        out.append('        setState(() { _availableBuses = []; });\n')
        out.append('        _busService.setTrackedBuses([]);\n')
        out.append('        return;\n')
        out.append('    }\n')
        out.append('    import_latlng_fallback = null;\n') # just a placeholder
        out.append('    LatLng? fromCoords;\n')
        out.append('    for (final entry in BusLocationService.keyPlaces.entries) {\n')
        out.append('        if (_busService.normalizeLocationName(entry.key) == fromText) {\n')
        out.append('            fromCoords = entry.value;\n')
        out.append('            break;\n')
        out.append('        }\n')
        out.append('    }\n')
        out.append('    if (fromCoords == null && (rawFromText.toLowerCase() == "current location" || rawFromText.isEmpty)) {\n')
        out.append('        fromCoords = _currentLocation;\n')
        out.append('    }\n')
        out.append('    final incoming = buses.where((b) {\n')
        out.append('      if (b.status != "RUNNING") return false;\n')
        out.append('      final toLower = toText.trim().toLowerCase();\n')
        out.append('      final fromLower = fromText.trim().toLowerCase();\n')
        out.append('      bool matchesRoute = true;\n')
        out.append('      if (toLower.isNotEmpty) {\n')
        out.append('           matchesRoute = b.to.toLowerCase() == toLower || b.routeName.toLowerCase().contains(toLower) || b.routeName.toLowerCase().contains(fromLower);\n')
        out.append('           if (!matchesRoute) {\n')
        out.append('               if ((fromLower.contains("erumely") && toLower.contains("koovappally")) || (fromLower.contains("koovappally") && toLower.contains("kottayam")) || (fromLower.contains("kanjirappally") && toLower.contains("kottayam")) || (fromLower.contains("ponkunnam") && toLower.contains("kottayam"))) {\n')
        out.append('                    matchesRoute = b.routeName.contains("Erumely - Kottayam") || (b.from.toLowerCase().contains("erumely") && b.to.toLowerCase().contains("kottayam"));\n')
        out.append('               } else if ((fromLower.contains("kottayam") && toLower.contains("koovappally")) || (fromLower.contains("koovappally") && toLower.contains("erumely")) || (fromLower.contains("kottayam") && toLower.contains("kanjirappally")) || (fromLower.contains("kottayam") && toLower.contains("ponkunnam"))) {\n')
        out.append('                    matchesRoute = b.routeName.contains("Kottayam - Erumely") || (b.from.toLowerCase().contains("kottayam") && b.to.toLowerCase().contains("erumely"));\n')
        out.append('               } else {\n')
        out.append('                   matchesRoute = (b.from.toLowerCase().contains(fromLower) || fromLower.isEmpty) && (b.to.toLowerCase().contains(toLower) || toLower.isEmpty);\n')
        out.append('               }\n')
        out.append('          }\n')
        out.append('      }\n')
        out.append('      if (!matchesRoute) return false;\n')
        out.append('      return _busService.isIncoming(b, relativeTo: fromCoords);\n')
        out.append('    }).toList();\n')
        out.append('    incoming.sort((a, b) {\n')
        out.append('        final etaA = _busService.etaMinutes(a, relativeTo: fromCoords);\n')
        out.append('        final etaB = _busService.etaMinutes(b, relativeTo: fromCoords);\n')
        out.append('        return etaA.compareTo(etaB);\n')
        out.append('    });\n')
        out.append('    final top3BusIds = incoming.take(3).map((b) => b.busId).toList();\n')
        out.append('    _busService.setTrackedBuses(top3BusIds);\n')
        out.append('    final loc = AppLocalizations.of(context);\n')
        out.append('    _availableBuses = incoming.map((bus) {\n')
        out.append('      final eta = _busService.etaMinutes(bus, relativeTo: fromCoords);\n')
        out.append('      return BusOption(\n')
        out.append('        id: bus.busId, name: loc.translate(bus.busName), type: loc.translate("Live"),\n')
        out.append('        time: StringUtils.formatTime(DateTime.now().add(Duration(minutes: eta))),\n')
        out.append('        departureTime: DateTime.now().add(Duration(minutes: eta)),\n')
        out.append('        duration: loc.translate("Var"), price: 20.0, seatsLeft: 40,\n')
        out.append('        origin: loc.translate(bus.from), destination: loc.translate(bus.to),\n')
        out.append('        arrivalTimeAtOrigin: "", arrivalTimeAtDestination: "",\n')
        out.append('        liveBusData: bus, minutesToUser: eta, arrivalAtUserStr: "\ \",\n')
        out.append('      );\n')
        out.append('    }).toList();\n')
        out.append('  }\n')
        
        continue
        
    if line.startswith('  /// Called ONLY when the user presses the GPS button'):
        in_update_bus_list = False
        
    if not in_update_bus_list:
        out.append(line)

with open('lib/screens/shortest_route_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(out)

print("done")
