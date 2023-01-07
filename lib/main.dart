import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Opus",
      home: Opus(),
    );
  }
}

class Opus extends StatefulWidget {
  const Opus({super.key});

  @override
  State<Opus> createState() => _OpusState();
}

class _OpusState extends State<Opus> {
  bool _nfcAvailable = false;

  NfcTag? _tag;
  String? _id;

  Uint8List _convertHex(String hex) {
    assert(hex.length % 2 == 0);

    final list = Uint8List(hex.length / 2 as int);
    for (int i = 0; i < list.length; i++) {
      list[i] = (int.parse(hex[i * 2], radix: 16) << 4) +
          int.parse(hex[i * 2 + 1], radix: 16);
    }

    return list;
  }

  void _read() async {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        setState(() => _tag = tag);
        NfcManager.instance.stopSession();

        // final opus = Iso7816.from(tag);
        // if (opus != null) {}

        final android = IsoDep.from(tag);
        if (android != null) {
          // ID
          android.transceive(data: _convertHex("94A4000002000219"));
          final list =
              await android.transceive(data: _convertHex("94B201041D"));

          setState(() {
            _id = list.fold("", (prev, i) => "$prev${i.toRadixString(16)}");
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    NfcManager.instance
        .isAvailable()
        .then((available) => setState(() => _nfcAvailable = available));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Opus reader"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _nfcAvailable ? _read : null,
            child: const Text("Read opus"),
          ),
          if (_tag != null)
            ListTile(
              title: Text(_tag.toString()),
              subtitle: const Text("Tag"),
            ),
          if (_id != null)
            ListTile(
              title: Text(_id!),
              subtitle: const Text("id"),
            ),
        ],
      ),
    );
  }
}
