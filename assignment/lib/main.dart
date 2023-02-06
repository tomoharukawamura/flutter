import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.lightGreen,
      ),
      home: const MyHomePage(title: '混雑情報'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Widget> cards = [];
  bool existOutlet = false;
  bool isEmpty = false;
  final controller = TextEditingController();
  int necessaryPeople = 0;
  bool isDecendingOrder = false;
  List<String> isFavorite = [];
  bool pickupFavorite = false;

  void _refresh() async {
    var url = Uri.parse(
        'https://mocha-api.t.u-tokyo.ac.jp/resource/channel/utokyo_all/congestion');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonObj = convert.jsonDecode(response.body);
      List<dynamic> congestions = jsonObj['congestions'];
      if (existOutlet) {
        congestions =
            congestions.where((e) => e['space']['outletCount'] > 0).toList();
        if (isDecendingOrder) {
          congestions.sort((a, b) =>
              b['space']['outletCount'].compareTo(a['space']['outletCount']));
        }
      }

      if (isEmpty) {
        if (necessaryPeople == 0) {
          debugPrint('人数が入力されていません');
        } else {
          congestions = congestions
              .where((e) =>
                  e['space']['capacity'] - e['headcount'] >= necessaryPeople)
              .toList();
        }
      }

      if (pickupFavorite) {
        congestions = congestions
            .where((e) => isFavorite.contains(e['space']['nameJa']))
            .toList();
      }

      cards = []; // ③ 通信が成功したのでカードリストを初期化

      for (Map<String, dynamic> congestion in congestions) {
        var headcount = congestion['headcount']; // 滞在者の人数
        Map<String, dynamic> space = congestion['space'];
        var name = space['nameJa']; // スペースの名前
        var capacity = space['capacity']; // スペースの容量
        var outletCount = space['outletCount']; // コンセントの数
        var info = "$name:($headcount/$capacity)[$outletCount]";

        // ④ カードをカードリストに追加し、変更箇所を画面に反映
        setState(() {
          cards.add(
            Card(
                child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListTile(
                  title: Text(info),
                  onTap: () {
                    if (isFavorite.contains(name)) {
                      setState(() {
                        isFavorite.remove(name);
                      });
                    } else {
                      setState(() {
                        isFavorite.add(name);
                      });
                    }
                  }),
            )),
          );
        });
      }
    } else if (response.statusCode == 500) {
      // エラーハンドリング
      debugPrint("server-side error");
    } else {
      // エラーハンドリング
      debugPrint("unkwon error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("混雑情報"),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Checkbox(
                value: existOutlet,
                onChanged: (bool? value) {
                  setState(() {
                    existOutlet = value!;
                  });
                }),
            const Text("コンセントがある部屋を表示する"),
          ]),
          Visibility(
              visible: existOutlet,
              child: Row(children: [
                Checkbox(
                    value: isDecendingOrder,
                    onChanged: (bool? value) {
                      setState(() {
                        isDecendingOrder = value!;
                      });
                    }),
                const Text("コンセント数の多い順に並べる")
              ])),
          const Padding(padding: EdgeInsets.all(5.0)),
          Row(children: [
            Checkbox(
                value: isEmpty,
                onChanged: (bool? value) {
                  setState(() {
                    isEmpty = value!;
                  });
                }),
            const Text('空き部屋を表示する'),
          ]),
          Visibility(
              visible: isEmpty,
              child: Column(children: [
                const Text("何人分の空きが必要?"),
                Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextField(
                      controller: controller,
                      onChanged: (value) {
                        setState(() {
                          necessaryPeople = int.parse(value);
                        });
                      },
                    ))
              ])),
          Row(
            children: [
              Checkbox(
                  value: pickupFavorite,
                  onChanged: (bool? value) {
                    setState(() {
                      pickupFavorite = value!;
                    });
                  }),
              const Text("お気に入りを表示")
            ],
          ),
          Flexible(
              child: ListView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            itemBuilder: (BuildContext context, int index) {
              return cards[index];
            },
          )),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        // ② refreshボタンが押されたタイミングで、APIにアクセスして
        // 画面を更新するメソッドを呼ぶ
        onPressed: _refresh,
        tooltip: 'Increment',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
