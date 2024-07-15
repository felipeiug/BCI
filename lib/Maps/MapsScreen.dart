import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:bci/Maps/openFile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleMaps extends StatefulWidget {
  @override
  State<GoogleMaps> createState() => GoogleMapsState();
}

class GoogleMapsState extends State<GoogleMaps> {
  static final CameraPosition _ufv = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(-19.217901419929596, -46.223750822246075),
    tilt: 59.440717697143555,
    zoom: 17,
  );

  double _zoom = 14.4746;
  LatLng _posAns = LatLng(0, 0);

  bool moveToMe = false;

  bool iniciar = false;
  bool entrando = true;

  GoogleMapController? _controller;

  Widget tapMarker = Container();
  double pinPosition = -100;

  Set<Marker> _markers = HashSet<Marker>();

  List<MarkerController> markersList = [];

  @override
  void initState() {
    super.initState();

    _abrirArquivoAnterior();
  }

  void _permissoes() async {
    int statuses = 0;
    permissions.PermissionStatus status =
        await permissions.Permission.storage.status;

    if (!status.isGranted) {
      status = await permissions.Permission.storage.request();
      if (!(status.isGranted)) {
        iniciar = false;
      } else {
        statuses += 1;
      }
    } else {
      statuses += 1;
    }

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    Location location = new Location();

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        iniciar = false;
      } else {
        statuses += 1;
      }
    } else {
      statuses += 1;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        iniciar = false;
      } else {
        statuses += 1;
      }
    } else {
      statuses += 1;
    }

    if (statuses >= 3) {
      iniciar = true;
    }

    if (iniciar == true) {
      if (entrando) {
        setState(() {
          _abrirArquivoAnterior();
          entrando = false;
        });
      }
    } else {
      if (entrando) {
        setState(() {
          OpenFile.excludeCache();
          entrando = false;
        });
      }
    }
  }

  void _abrirArquivoAnterior() async {
    pinPosition = -100;
    permissions.PermissionStatus status =
        await permissions.Permission.storage.status;

    if (status.isGranted) {
      markersList = await OpenFile.openLatest();
      _gerarMarkers();
    }
  }

  void _saveFile() async {
    OpenFile.saveDataFile(context);
  }

  void _openFile() async {
    try {
      List<MarkerController> _a = await OpenFile.openFile();
      if (_a.length > 0) {
        markersList = _a;
      } else {
        markersList = [];
      }
      _gerarMarkers();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao tentar abrir um arquivo: $e",
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _gerarMarkers() {
    if (markersList.length == 0) {
      _markers.clear();
      moveToMe = true;
    } else {
      _markers.clear();
      markersList.forEach((markerItem) {
        //moveToMe = true;////////////////

        _markers.add(
          Marker(
            markerId: MarkerId(markerItem.id),
            position: markerItem.position,
            icon: markerItem.icon,
            draggable: markerItem.draggable,
            onTap: () {
              _tapMarker(markerItem.args, markerItem);
            },
            onDragEnd: (pos) {
              _setPosMarker(pos, markerItem, markerItem.args);
            },
          ),
        );
      });
    }

    setState(() {});
  }

  void _setPosMarker(LatLng pos, MarkerController marker, Map args) async {
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: _zoom,
          bearing: 0,
        ),
      ),
    );

    Map boletim = args['boletim'];

    int index = 0;
    boletim['enderecos'].forEach((endereco) {
      if (endereco['adress'] == args['nome']) {
        boletim['enderecos'][index]['lat'] = pos.latitude;
        boletim['enderecos'][index]['lon'] = pos.longitude;

        OpenFile.saveData(boletim);
      }
      index += 1;
    });

    markersList.forEach((_marker) {
      if (_marker.id == marker.id) {
        marker.position = pos;
      }
    });
  }

  void _onMapCreated(GoogleMapController ctrl) async {
    _controller = ctrl;

    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      return;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      return;
    }

    location.onLocationChanged.listen((LocationData location) async {
      if (moveToMe) {
        double lat = double.parse(location.latitude.toString());
        double lon = double.parse(location.longitude.toString());
        double direction = 0;

        direction = atan((lon - _posAns.longitude) / (lat - _posAns.latitude));

        _posAns = LatLng(lat, lon);

        ctrl.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(lat, lon),
              zoom: _zoom,
              bearing: direction,
            ),
          ),
        );
      }
    });
  }

  void _cameraMove(CameraPosition posCam) async {
    if (posCam.zoom != _zoom) {
      _zoom = posCam.zoom;
    }
    //Outras coisas podem ser adicionadas aqui
  }

  void _tapMap(LatLng pos) async {}

  void _tapMarker(Map args, MarkerController marker) async {
    tapMarker = Container(
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(boxShadow: <BoxShadow>[
        BoxShadow(
          spreadRadius: 5,
          blurRadius: 7,
          color: Colors.grey.withOpacity(0.2),
          offset: Offset(0, 3),
        )
      ]),
      child: Card(
        child: ListTile(
          title: Text(args['nome']),
          leading: IconButton(
            icon: Icon(Icons.open_in_new, color: Colors.black),
            onPressed: () async {
              await OpenFile.openData(args, context);
              _abrirArquivoAnterior();
            },
          ),
        ),
      ),
    );

    setState(() {
      pinPosition = 10;
      moveToMe = false;
    });
  }

  void _dialogEndereco(BuildContext _ctx) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    showDialog(
        context: _ctx,
        builder: (BuildContext ctx) {
          String rua = "",
              numero = "",
              complemento = "",
              bairro = "",
              cidade = prefs.getString("cidade") ?? "",
              estado = prefs.getString("estado") ?? "",
              cep = prefs.getString("cep") ?? "";

          TextEditingController _cidade = TextEditingController(text: cidade);
          TextEditingController _estado = TextEditingController(text: estado);
          TextEditingController _cep = TextEditingController(text: cep);

          return AlertDialog(
            actions: [
              CupertinoButton(
                child: Text("Cancelar"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              CupertinoButton(
                child: Text("Adicionar"),
                onPressed: () {
                  if (rua != "" &&
                      numero != "" &&
                      bairro != "" &&
                      cidade != "" &&
                      estado != "" &&
                      cep != "") {
                    Map a = {
                      'endereco': rua + ", Nº " + numero,
                      'complemento': complemento,
                      'bairro': bairro,
                      'cidade': cidade,
                      'estado': estado,
                      'cep': cep,
                    };

                    prefs.setString("cidade", cidade);
                    prefs.setString("estado", estado);
                    prefs.setString("cep", cep);

                    Navigator.pop(context, a);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Complete todos os campos obrigatórios",
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
            title: Text(
              "Endereço do Local",
              style: TextStyle(fontSize: 18),
            ),
            contentPadding: EdgeInsets.all(20),
            content: SingleChildScrollView(
              child: Container(
                height: 250,
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        flex: 5,
                        child: TextField(
                          onChanged: (text) {
                            rua = text;
                          },
                          decoration: InputDecoration(hintText: "Rua"),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                        height: 5,
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          onChanged: (text) {
                            numero = text;
                          },
                          decoration: InputDecoration(hintText: "Nº"),
                        ),
                      ),
                    ]),
                    Expanded(
                      child: TextField(
                        onChanged: (text) {
                          complemento = text;
                        },
                        decoration: InputDecoration(hintText: "Complemento"),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        onChanged: (text) {
                          bairro = text;
                        },
                        decoration: InputDecoration(hintText: "Bairro"),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _cidade,
                        onChanged: (text) {
                          cidade = text;
                        },
                        decoration: InputDecoration(hintText: "Cidade"),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _estado,
                        onChanged: (text) {
                          estado = text;
                        },
                        decoration: InputDecoration(hintText: "Estado"),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _cep,
                        onChanged: (text) {
                          cep = text;
                        },
                        decoration: InputDecoration(hintText: "CEP"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).then((value) async {
      if (value == null) {
        return;
      }
      value['lat'] = _posAns.latitude;
      value['lon'] = _posAns.longitude;

      markersList = await OpenFile.addMarker(value, context);
      _gerarMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    _permissoes();

    return !(iniciar)
        ? Container(
            color: Colors.blue[100],
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Card(
                    child: ListTile(
                      title: Text(
                        'Você não aceitou todas as permissões para acessar o app ou não ativou a localização do dispositivo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Card(
                    color: Colors.amber,
                    child: ListTile(
                      title: Text(
                        'Clique aqui para abrir as configurações do app (reinicie o app após configurar)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                      onTap: () {
                        permissions.openAppSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text("CTM"),
              actions: [
                IconButton(
                  icon: Icon(Icons.pin_drop),
                  onPressed: () {
                    moveToMe = true;
                    _dialogEndereco(context);
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: Icon(
                    moveToMe
                        ? Icons.gps_fixed_outlined
                        : Icons.gps_off_outlined,
                  ),
                  onPressed: () {
                    moveToMe = !moveToMe;
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: Icon(Icons.file_present_sharp),
                  onPressed: _openFile,
                ),
                IconButton(
                  icon: Icon(Icons.save_alt),
                  onPressed: _saveFile,
                ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Container(
                    child: GoogleMap(
                      mapType: MapType.hybrid,
                      initialCameraPosition: _ufv,
                      onMapCreated: _onMapCreated,
                      onCameraMove: _cameraMove,
                      onTap: (latlon) {
                        _tapMap(latlon);
                        setState(() {
                          pinPosition = -100;
                        });
                      },
                      myLocationEnabled: moveToMe,
                      myLocationButtonEnabled: true,
                      compassEnabled: true,
                      trafficEnabled: true,
                      mapToolbarEnabled: true,
                      markers: _markers,
                    ),
                  ),
                  AnimatedPositioned(
                    top: pinPosition,
                    right: 0,
                    left: 0,
                    duration: Duration(milliseconds: 1000),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: tapMarker,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

class MarkerController {
  MarkerController({
    required this.draggable,
    required this.id,
    required this.position,
    required this.icon,
    required this.args,
  });

  final String id;
  bool draggable;
  LatLng position;
  BitmapDescriptor icon;
  Map args;
}
