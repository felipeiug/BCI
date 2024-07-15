import 'dart:async';

import 'package:bci/Maps/openFile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import "dart:convert";

class BoletimScreen extends StatefulWidget {
  BoletimScreen(this.args);
  final Map args;
  @override
  State<BoletimScreen> createState() => BoletimScreenState();
}

class BoletimScreenState extends State<BoletimScreen> {
  List? items;
  bool primeiro = true;
  Map boletim = {};

  Timer? currentTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  dynamic gerarItems(Map? args) {
    List lista = [];

    if (args == null) {
      return [];
    }

    args.forEach((key, value) {
      if (value is Map) {
        Widget itemExpandir = gerarItemsExpandir(value, [key]);
        lista.add(
          itemExpandir,
        );
      } else {
        if (value == "int" || value is int) {
          if (value == "int") {
            value = 0;
          }
          lista.add(
            itemInt(
              key,
              value,
              (String text, List indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 500), () {
                  int? number = int.tryParse(text);

                  if (number == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("O valor deve ser um inteiro"),
                    ));
                    return;
                  }

                  dynamic valor = widget.args['dadosImovel'];

                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = number;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              [key],
            ),
          );
        } else if (value == "float" || value is double) {
          if (value == "float") {
            value = 0.0;
          }
          lista.add(
            itemDouble(
              key,
              value,
              (String text, List indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 500), () {
                  text = text.replaceAll(",", ".");

                  double? value;

                  value = double.tryParse(text);

                  if (value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("O valor deve ser um número"),
                      duration: Duration(seconds: 1),
                    ));
                    return;
                  }

                  dynamic valor = widget.args['dadosImovel'];

                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = value;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              [key],
            ),
          );
        } else if (value == "bool" || value is bool) {
          if (value == "bool") {
            value = false;
          }
          lista.add(
            itemBool(
              key,
              value,
              (String text, List indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 500), () {
                  bool value = false;

                  text = text.toUpperCase();
                  text = text.replaceAll(" ", "").replaceAll("Ã", "A");

                  if (text == "SIM") {
                    value = true;
                  } else if (text == "NAO") {
                    value = false;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("O valor deve ser SIM ou NÃO"),
                    ));
                    return;
                  }

                  dynamic valor = widget.args['dadosImovel'];

                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = value;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              [key],
            ),
          );
        }
        //Tem que ser o ultimo
        else if (value is String || value == "str") {
          if (value == "str") {
            value = "";
          }
          lista.add(
            itemStr(
              key,
              value,
              (text, indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 500), () {
                  dynamic valor = widget.args['dadosImovel'];
                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = text;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              [key],
            ),
          );
        }
      }
    });

    return lista;
  }

  Widget gerarItemsExpandir(Map args, List indexes) {
    List<Widget> items = [];

    String titulo = indexes[indexes.length - 1];

    args.forEach((key, value) {
      if (value is Map) {
        indexes.add(key);

        Widget itemExpandir = gerarItemsExpandir(value, indexes);
        items.add(
          itemExpandir,
        );
      } else {
        if (value == "int" || value is int) {
          if (value == "int") {
            value = 0;
          }
          items.add(itemInt(
            key,
            value,
            (String text, List indexes) {
              if (currentTimer != null) {
                currentTimer!.cancel();
              }
              currentTimer = Timer(Duration(milliseconds: 1000), () {
                int? number = int.tryParse(text);

                if (number == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("O valor deve ser um inteiro"),
                  ));
                  return;
                }

                dynamic valor = widget.args['dadosImovel'];

                indexes.forEach((_key) {
                  if (_key != indexes[indexes.length - 1]) {
                    valor = valor[_key];
                  }
                });
                valor[indexes[indexes.length - 1]] = number;

                int index = 0;
                int _index = 0;
                boletim['enderecos'].forEach((value) {
                  if (value['adress'] == widget.args['nome']) {
                    _index = index;
                  }
                  index += 1;
                });
                boletim['enderecos'][_index]["dadosImovel"] =
                    json.decode(json.encode(widget.args['dadosImovel']));
                OpenFile.saveData(boletim);
              });
            },
            indexes + [key],
          ));
        } else if (value == "float" || value is double) {
          if (value == "float") {
            value = 0.0;
          }
          items.add(
            itemDouble(
              key,
              value,
              (String text, List indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 1000), () {
                  text = text.replaceAll(",", ".");

                  double? value;

                  value = double.tryParse(text);

                  if (value == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("O valor deve ser um número"),
                      duration: Duration(seconds: 1),
                    ));
                    return;
                  }

                  dynamic valor = widget.args['dadosImovel'];

                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = value;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              indexes + [key],
            ),
          );
        } else if (value == "bool" || value is bool) {
          if (value == "bool") {
            value = false;
          }
          items.add(
            itemBool(
              key,
              value,
              (String text, List indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 3000), () {
                  bool value = false;

                  text = text.toUpperCase();
                  text = text.replaceAll(" ", "").replaceAll("Ã", "A");

                  if (text == "SIM") {
                    value = true;
                  } else if (text == "NAO") {
                    value = false;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("O valor deve ser SIM ou NÃO"),
                      duration: Duration(seconds: 1),
                    ));
                    return;
                  }

                  dynamic valor = widget.args['dadosImovel'];

                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = value;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              indexes + [key],
            ),
          );
        }
        //Tem que ser o ultimo
        else if (value is String || value == "str") {
          if (value == "str") {
            value = "";
          }
          items.add(
            itemStr(
              key,
              value,
              (text, indexes) {
                if (currentTimer != null) {
                  currentTimer!.cancel();
                }
                currentTimer = Timer(Duration(milliseconds: 1000), () {
                  dynamic valor = widget.args['dadosImovel'];
                  indexes.forEach((_key) {
                    if (_key != indexes[indexes.length - 1]) {
                      valor = valor[_key];
                    }
                  });
                  valor[indexes[indexes.length - 1]] = text;

                  int index = 0;
                  int _index = 0;
                  boletim['enderecos'].forEach((value) {
                    if (value['adress'] == widget.args['nome']) {
                      _index = index;
                    }
                    index += 1;
                  });
                  boletim['enderecos'][_index]["dadosImovel"] =
                      json.decode(json.encode(widget.args['dadosImovel']));
                  OpenFile.saveData(boletim);
                });
              },
              indexes + [key],
            ),
          );
        }
      }
    });

    Widget listView = Column(
      children: <Widget>[ListTile(title: Text(titulo)), Divider(thickness: 2)] +
          items,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      child: listView,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38, width: 2.5),
        color: Colors.white24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    boletim = widget.args['boletim'];
    Map args = {};

    if (widget.args['dadosImovel'].length == 0) {
      args = json.decode(json.encode(widget.args['boletim']['conteudo']));
      widget.args['dadosImovel'] = args;
    } else {
      args = widget.args['dadosImovel'];
    }
    items = <dynamic>[ListTile(title: Text(widget.args['nome']))] +
        gerarItems(args);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Dados do Imóvel"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black12,
        padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
        child: ListView.builder(
          itemBuilder: (ctx, index) {
            return items![index];
          },
          itemCount: items != null ? items!.length : 0,
        ),
      ),
    );
  }
}

Widget itemStr(String text, String value, Function onText, List indexes) {
  TextEditingController _controller = TextEditingController(text: value);
  return Container(
    child: Card(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(text),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _controller,
                onChanged: (t) {
                  onText(t, indexes);
                },
                decoration: InputDecoration(helperText: "Texto"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget itemInt(String text, int value, Function onText, List indexes) {
  TextEditingController _controller =
      TextEditingController(text: value.toString());
  return Container(
    child: Card(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(text),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _controller,
                onChanged: (t) {
                  onText(t, indexes);
                },
                decoration: InputDecoration(helperText: "Número inteiro"),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget itemBool(String text, bool value, Function onText, List indexes) {
  String texto = value ? "Sim" : "Não";
  TextEditingController _controller = TextEditingController(text: texto);
  return Container(
    child: Card(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(text),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _controller,
                onChanged: (t) {
                  onText(t, indexes);
                },
                decoration: InputDecoration(helperText: "Sim/Não"),
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget itemDouble(String text, double value, Function onText, List indexes) {
  String texto = value.toString();
  TextEditingController _controller = TextEditingController(text: texto);
  return Container(
    child: Card(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(text),
            ),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _controller,
                onChanged: (t) {
                  onText(t, indexes);
                },
                decoration: InputDecoration(helperText: "Número"),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
