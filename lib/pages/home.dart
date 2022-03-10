import 'package:flutter/material.dart';
import 'package:livestream_apps/pages/director.dart';
import 'package:livestream_apps/pages/participant.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _userName = TextEditingController();
  final _channelName = TextEditingController();
  late int? uid;

  @override
  void initState() {
    super.initState();
    getUserUid();
  }

  Future<void> getUserUid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? storedUid = preferences.getInt('localUid');
    if (storedUid != null) {
      uid = storedUid;
      print('storedUid: $uid!');
    } else {
      int time = DateTime.now().microsecondsSinceEpoch;
      uid = int.parse(time.toString().substring(1, time.toString().length - 3));
      preferences.setInt('localUid', uid!);
      print('settingUid: $uid!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  "assets/streamer_connected.png",
                  alignment: AlignmentDirectional(0, 1),
                  width: 300,
                  height: 300,
                ),
              ),
              const Text(
                'Streaming everywhere and everytime',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(
                height: 40,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: _userName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    hintText: 'User Name',
                  ),
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: _channelName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    hintText: 'Channel Name',
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () async {
                      await [Permission.camera, Permission.microphone]
                          .request();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Participant(
                            channelName: _channelName.text,
                            userName: _userName.text,
                            uid: uid!,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Participant ',
                          style: TextStyle(fontSize: 20),
                        ),
                        Icon(Icons.live_tv),
                      ],
                    ),
                  ),
                  TextButton(
                    style: ButtonStyle(),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Director(
                            channelName: _channelName.text,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Director ',
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                        Icon(
                          Icons.cut,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
