import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pretty_json/pretty_json.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var position;

  @override
  void initState() {
    getCurrentLocationForDevice();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Rental"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20,),
            ElevatedButton(
              child: Container(
                margin: const EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.my_location_rounded),
                    SizedBox(width: 10,),
                    Text("Get current location")
                  ],
                ),
              ),
              onPressed: () async {
                setState(() {
                  getCurrentLocationForDevice();
                });
              },
            ),
            const SizedBox(height: 20,),
            Center(
              child: Text("CURRENT LATITUDE : ${(position != null) ? ((position as Position).latitude) : ("--")}"),
            ),
            const SizedBox(height: 10,),
            Center(
              child: Text("CURRENT LONGITUDE : ${(position != null) ? ((position as Position).longitude) : ("--")}"),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("car").snapshots(),
              builder: (context, driverSnaps) {
                if(driverSnaps.connectionState == ConnectionState.active) {
                  List cars = (driverSnaps.data!.docs.first.data() as Map)["carDetails"];

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("location").snapshots(),
                    builder: (context, locationSnaps) {
                      if(locationSnaps.connectionState == ConnectionState.active) {
                        List locations = (locationSnaps.data!.docs.first.data() as Map)["locationDetails"];

                        List<Map<String, dynamic>> finalDrivers = [];

                        locations.sort((a,b) => Geolocator.distanceBetween(position.latitude, position.longitude, (a["location"] as GeoPoint).latitude, a["location"].longitude).compareTo(Geolocator.distanceBetween(position.latitude, position.longitude, b["location"].latitude, b["location"].longitude)));
                        for(int i=0; i<locations.length; i++){
                          var driverID, number_plate;
                          cars.forEach((element) {
                            if(element["id"] == locations[i]["id"]) {
                              driverID = element["driver"];
                              number_plate = element["number_plate"];
                            }
                          });

                          finalDrivers.add({
                            "id" : locations[i]["id"],
                            "latitude" : (locations[i]["location"] as GeoPoint).latitude,
                            "longitude" : (locations[i]["location"] as GeoPoint).longitude,
                            "driver" : driverID,
                            "number_plate" : number_plate
                          });
                        }
                        return Expanded(
                          child: ListView.separated(
                            itemCount: finalDrivers.length,
                            separatorBuilder: (context, index) {return const Divider(thickness: 2,);},
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(prettyJson(finalDrivers[index], indent: 2)),
                              );
                            },
                          ),
                        );
                      }
                      else {
                        return const Text("Tap on get current location");
                      }
                    },
                  );
                }
                else {
                  return const Text("Please wait...");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void getCurrentLocationForDevice() async {
    Position tempPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      position = tempPosition;
    });
  }
}