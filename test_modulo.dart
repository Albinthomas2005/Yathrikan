// temporary test
void main() {
  int uIdx = 0;
  int busIndex = 900;
  int routeLength = 1000;
  int dist = (uIdx - busIndex) % routeLength;
  print("Dart modulo result: $dist");
}
