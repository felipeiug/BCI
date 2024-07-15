import 'dart:convert';
import 'dart:io';

import 'package:bci/Boletim/boletimScreen.dart';
import 'package:bci/Maps/MapsScreen.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenFile {
  //Ao iniciar abre os arquivos para que seja possível abrir um arquivo json
  static Future<List<MarkerController>> openFile() async {
    String? path;

    String dados = "";

    FlutterDocumentPickerParams params = FlutterDocumentPickerParams(
      allowedFileExtensions: ['json'],
    );
    try {
      path = await FlutterDocumentPicker.openDocument(params: params);
      dados = File(path!).readAsStringSync();
    } catch (e) {
      print(e);
      return [];
    }

    if (path == null) {
      return [];
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (dados != "") {
      prefs.setString('currentArq', dados);
    }

    Map dadosBCI = await json.decode(dados);

    OpenFile openFile = OpenFile();

    return openFile.gerarItems(dadosBCI);
  }

  static Future<List<MarkerController>> openLatest() async {
    List<MarkerController>? retornar = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? dados = prefs.getString('currentArq');

    if (dados == null) {
      return [];
    }

    Map dadosBCI = await json.decode(dados);

    OpenFile openFile = OpenFile();

    return openFile.gerarItems(dadosBCI);
  }

  static Future<List<MarkerController>> addMarker(
      Map newItem, BuildContext ctx) async {
    List<MarkerController>? retornar = [];

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? dados = prefs.getString('currentArq');

    if (dados == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possivel adicionar o endereço: Nenhum arquivo CTM aberto',
          ),
        ),
      );
      return [];
    }

    Map dadosBCI = await json.decode(dados);

    String endereco = newItem['endereco'] +
        ", " +
        newItem['complemento'] +
        ", " +
        newItem['bairro'] +
        ". " +
        newItem['cidade'] +
        ", " +
        newItem['estado'] +
        ", Brasil. CEP: " +
        newItem['cep'];

    if (!dadosBCI.containsKey('enderecos')) {
      dadosBCI['enderecos'] = [];
    }
    dadosBCI['enderecos'].add({
      'adress': endereco,
      'lat': newItem['lat'],
      'lon': newItem['lon'],
      'licensa': 'O autor',
    });

    OpenFile.saveData(dadosBCI);

    OpenFile openFile = OpenFile();

    return openFile.gerarItems(dadosBCI);
  }

  static Future<void> openData(Map args, BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BoletimScreen(args),
      ),
    );
  }

  static void saveData(Map boletim) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String value = jsonEncode(boletim);

    prefs.setString('currentArq', value);
  }

  static void saveDataFile(BuildContext ctx) async {
    String pathSave = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOCUMENTS);

    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? dados = prefs.getString('currentArq');

    if (dados == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text("Você ainda não adicionou nenhum endereço"),
        ),
      );
      return;
    }

    Map _value = await json.decode(dados);

    //////////////////////////////////////////////////

    String campos = "ID,LATITUDE,LONGITUDE,ENDERECO";
    List<String> keys = [];

    int id = 1;
    bool addCampos = true;

    if (_value.containsKey('enderecos')) {
      _value['enderecos'].forEach((value) {
        String dadosImovel = "";
        if (value.containsKey("dadosImovel")) {
          value['dadosImovel'].forEach((key, value) {
            if (addCampos) {
              campos += ",${key.toUpperCase()}";
            }
            if (value is Map) {
              dadosImovel += "," +
                  value
                      .toString()
                      .replaceAll(",", "->")
                      .replaceAll("{", "")
                      .replaceAll("}", "");
            } else {
              dadosImovel += "," + value.toString().replaceAll(",", "");
            }
          });
        }

        if (addCampos) {
          addCampos = false;
          campos += "\n";
        }

        campos +=
            "$id,${value['lat']},${value['lon']},${value['adress'].replaceAll(',', '.')}$dadosImovel\n";

        id += 1;
      });
    }

    ///////////////////////////////////////////////

    String value = campos; //json.encode(campos);

    ///////

    showDialog(
      context: ctx,
      builder: (ctx) {
        TextEditingController _controller = TextEditingController(text: "");

        return AlertDialog(
          title: Text("Qual o nome do arquivo a ser salvo?"),
          content: Container(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: "Nome"),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx, _controller.text);
              },
              child: Text("Salvar"),
            ),
          ],
        );
      },
    ).then((nameFile) {
      if (nameFile == null) {
        return;
      }
      if (nameFile == "") {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text("Escolha o nome para o arquivo!"),
          //duration: Duration(seconds: 1),
        ));
        return;
      }

      nameFile.replaceAll(".csv", "");

      File arqSave = File(pathSave + "/" + nameFile + ".csv");

      if (arqSave.existsSync()) {
        showDialog(
          context: ctx,
          builder: (ctx) {
            return AlertDialog(
              title: Text(
                  "Já existe um arquivo com o nome de $nameFile, deseja excluí-lo?"),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                  child: Text("Não"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx, true);
                  },
                  child: Text("Sim"),
                ),
              ],
            );
          },
        ).then((excluir) {
          if (excluir == false || excluir == null) {
            return;
          } else if (excluir == true) {
            arqSave.writeAsString(value);
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: Text("Arquivo salvo em: ${arqSave.path}"),
            ));
          }
        });
      } else {
        arqSave.writeAsString(value);
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text("Arquivo salvo em: ${arqSave.path}"),
        ));
      }
    });
  }

  static Future<bool> excludeCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.clear();
  }

  Future<List<MarkerController>> gerarItems(Map boletim) async {
    List<MarkerController> markers = [];

    if (!boletim.containsKey('enderecos')) {
      return [];
    }

    boletim['enderecos'].forEach((endereco) {
      String nome = endereco['adress'];
      String licensa = endereco['licensa'];
      LatLng coord = LatLng(endereco['lat'], endereco['lon']);
      Map dadosImovel =
          endereco.containsKey("dadosImovel") ? endereco['dadosImovel'] : {};

      markers.add(
        MarkerController(
          draggable: true,
          id: nome,
          position: coord,
          icon: dadosImovel.length > 0
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                )
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
          args: {
            'nome': nome,
            'licensa': licensa,
            'coord': coord,
            'dadosImovel': dadosImovel,
            'boletim': boletim,
          },
        ),
      );
    });

    return markers;
  }
}
