import 'package:motion_bridge/utils/network_manager.dart';

class MediaController {
  final NetworkManager _networkManager;

  MediaController(this._networkManager);

  void play() {
    _networkManager.sendPacket({"t": "MEDIA", "action": "PLAY"});
  }

  void pause() {
    _networkManager.sendPacket({"t": "MEDIA", "action": "PAUSE"});
  }

  void next() {
    _networkManager.sendPacket({"t": "MEDIA", "action": "NEXT"});
  }

  void previous() {
    _networkManager.sendPacket({"t": "MEDIA", "action": "PREV"});
  }
}

final mediaController = MediaController(NetworkManager());
