import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';

import '../utils/appId.dart';

class Participant extends StatefulWidget {
  final String channelName;
  final String userName;
  final int uid;
  const Participant(
      {Key? key,
      required this.channelName,
      required this.userName,
      required this.uid})
      : super(key: key);

  @override
  State<Participant> createState() => _ParticipantState();
}

class _ParticipantState extends State<Participant> {
  List<int> _users = [];
  late RtcEngine _engine;
  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;
  bool muted = false;
  bool videoDisabled = false;

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    _channel?.leave();
    _client?.logout();
    _client?.destroy();

    super.dispose();
  }

  Future<void> initializeAgora() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _client = await AgoraRtmClient.createInstance(appId);

    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);

    //Callbacks for the RTC Engine
    _engine.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, int? uid, elapsed) {
      setState(() {
        _users.add(uid!);
      });
    }, leaveChannel: (stats) {
      setState(() {
        _users.clear();
      });
    }));

    //Callbacks for the RTC Clients
    _client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print(
        'Private Message from ' + peerId + ': ' + (message.text),
      );
    };

    _client?.onConnectionStateChanged = (int state, int reason) {
      print('Connection state changed: ' +
          state.toString() +
          ', reason: ' +
          reason.toString());

      if (state == 5) {
        _channel?.leave();
        _client?.logout();
        _client?.destroy();
        print('Logged out');
      }
    };

    //Callbacks for RTM Channel
    _channel?.onMemberJoined = (AgoraRtmMember member) {
      print(
          'Member joined: ' + member.userId + ', channel: ' + member.channelId);
    };

    _channel?.onMemberLeft = (AgoraRtmMember member) {
      print('Member left: ' + member.userId + ', channel: ' + member.channelId);
    };

    _channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print('Public Message from ' + member.userId + ': ' + message.text);
    };

    // Join the RTM and RTC channels
    await _client?.login(
        '383e82e17b1549289fe18737f8bcb65d', widget.uid.toString());
    _channel = await _client?.createChannel(widget.channelName);
    await _channel?.join();
    await _engine.joinChannel('383e82e17b1549289fe18737f8bcb65d',
        widget.channelName, 'null', widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Participant',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
      ),
      body: Center(
        child: Stack(
          children: [
            _broadcastView(),
            _toolbar(),
          ],
        ),
      ),
    );
  }

  Widget _broadcastView() {
    if (_users.isEmpty) {
      return const Center(
        child: Text('No Users'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: RtcLocalView.SurfaceView(),
        ),
      ],
    );
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        RawMaterialButton(
          onPressed: _onToggleMute,
          child: Icon(
            muted ? Icons.mic_off : Icons.mic,
            color: muted ? Colors.white : Colors.blueAccent,
            size: 20,
          ),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor: muted ? Colors.blueAccent : Colors.white,
          padding: const EdgeInsets.all(12),
        ),
        RawMaterialButton(
          onPressed: () => _onCallEnd(context),
          child: const Icon(
            Icons.call_end,
            color: Colors.white,
            size: 35,
          ),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.redAccent,
          padding: const EdgeInsets.all(15),
        ),
        RawMaterialButton(
          onPressed: _onToggleVideoDisabled,
          child: Icon(
            videoDisabled ? Icons.videocam_off : Icons.videocam,
            color: videoDisabled ? Colors.white : Colors.blueAccent,
            size: 20,
          ),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor: videoDisabled ? Colors.blueAccent : Colors.white,
          padding: const EdgeInsets.all(12),
        ),
        RawMaterialButton(
          onPressed: _onSwitchCamera,
          child: Icon(
            Icons.switch_camera,
            color: Colors.blueAccent,
            size: 20,
          ),
          shape: const CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.white,
          padding: const EdgeInsets.all(12),
        ),
      ]),
    );
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideoDisabled() {
    setState(() {
      videoDisabled = !videoDisabled;
    });
    _engine.muteLocalAudioStream(videoDisabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }
}
