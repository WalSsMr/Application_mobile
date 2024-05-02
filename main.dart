import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biens App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<List<Map<String, dynamic>>> _loadBiens() async {
    final conn = await MySqlConnection.connect(
      ConnectionSettings(
        host: "127.0.0.1",
        port: 3306,
        user: "root",
        password: "root",
        db: "rentit",
      ),
    );
  print("Vous etes connecté");
    final results = await conn.query('SELECT nom, description, chemin_image FROM biens');
    await conn.close();

    return results.map((e) => e.fields).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biens'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadBiens(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            final biens = snapshot.data!;
            return ListView.builder(
              itemCount: biens.length,
              itemBuilder: (context, index) {
                final bien = biens[index];
                return ListTile(
                  title: Text(bien['nom']),
                  subtitle: Text(bien['description']),
                  leading: Image.asset(
                    bien['chemin_image'],
                    width: 100,
                    height: 100,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return DescriptifPage(
                          bien: bien,
                        );
                      },
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class DescriptifPage extends StatelessWidget {
  final Map<String, dynamic> bien;

  const DescriptifPage({super.key, required this.bien});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(bien['nom']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(bien['description']),
          Image.asset(
            bien['chemin_image'],
            width: 250,
            height: 250,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Retour'),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const ReservationForm();
                },
              );
            },
            child: const Text('Réserver'),
          ),
        ],
      ),
    );
  }
}

class ReservationForm extends StatefulWidget {
  const ReservationForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ReservationFormState createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();

  late String _firstName;
  late String _lastName;
  late DateTime _reservationDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Formulaire de réservation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
              onSaved: (value) {
                _firstName = value!;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
              onSaved: (value) {
                _lastName = value!;
              },
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Date de réservation'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une date';
                }
                return null;
              },
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime(2100),
                );
                if (picked != null && picked != _reservationDate) {
                  setState(() {
                    _reservationDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Réservation effectuée pour $_firstName $_lastName le $_reservationDate'),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }
}