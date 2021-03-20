import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoder/geocoder.dart';
import '../app.dart';

class LocationSearchDelegate extends SearchDelegate<Map> {

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  ThemeData appBarTheme(BuildContext context) {
    assert(context != null);
    final ThemeData theme = Theme.of(context);
    assert(theme != null);
    return theme.copyWith(
      primaryColor: MediaQuery.of(context).platformBrightness == Brightness.dark ? Colors.white10 : Colors.white,
      primaryIconTheme: theme.primaryIconTheme.copyWith(color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.white),
      primaryColorBrightness: MediaQuery.of(context).platformBrightness,
      primaryTextTheme: theme.textTheme,
    );
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Address>>(
      future: Geocoder.local.findAddressesFromQuery(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && !snapshot.hasError) {
          List<Address> addresses = snapshot.data;
          addresses.forEach((address) {
            print("Address Line: ${address.addressLine},\nAdmin Area: ${address.adminArea},\nFeature Name: ${address.featureName},\nLocality: ${address.locality},\nSub Admin Area: ${address.subAdminArea},\nSub Locality: ${address.subLocality},\nSub Thoroughfare: ${address.subThoroughfare},\nThoroughfare: ${address.thoroughfare}\n---------------------\n");
          });
          return ListView.separated(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              Address address = addresses[index];
              List featuredAddress = [address.locality, '${address.locality ?? ''}, ${address.adminArea ?? ''}', address.subLocality ?? '', address.adminArea ?? '', address.featureName ?? ''];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${address.featureName ?? address.subLocality}', style: Theme.of(context).textTheme.headline6.copyWith(fontFamily: RivalFonts.feature),),
                    Text('${address.addressLine}', style: Theme.of(context).textTheme.bodyText1,),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: SizedBox(
                        height: 32,
                        child: ListView.builder(
                          physics: BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: featuredAddress.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: ChoiceChip(
                              label: Text(featuredAddress[index]),
                              selected: false,
                              onSelected: (value) {
                                Navigator.of(context).pop({
                                  'geoPoint': GeoPoint(address.coordinates.latitude, address.coordinates.longitude),
                                  'location': featuredAddress[index]
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => Divider(),
          );
        } else if (snapshot.connectionState == ConnectionState.done && !snapshot.hasData) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: Theme.of(context).textTheme.headline2.fontSize,),
                    Text('No Result Found', style: Theme.of(context).textTheme.headline5.copyWith(fontFamily: RivalFonts.feature),),
                  ],
                )
              )
            ],
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(child: CustomProgressIndicator())
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // This method is called everytime the search term changes. 
    // If you want to add search suggestions as the user enters their search term, this is the place to do that.
    return Column();
  }
}