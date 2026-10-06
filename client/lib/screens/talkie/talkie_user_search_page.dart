import 'package:flutter/material.dart';
import 'package:talkie_v2/models/admin_model.dart';
import 'package:talkie_v2/services/admin_service.dart';
import 'package:talkie_v2/utils/global.dart';
import 'package:talkie_v2/utils/string_utils.dart';
import 'package:talkie_v2/widgets/progress_hud.dart';
import 'package:toastification/toastification.dart';

class TalkieUserSearchPage extends StatefulWidget {
  final Function(User user) onSelectItem;

  const TalkieUserSearchPage({super.key, required this.onSelectItem});

  @override
  State<TalkieUserSearchPage> createState() => _TalkieUserSearchPageState();
}

class _TalkieUserSearchPageState extends State<TalkieUserSearchPage> {
  final TextEditingController _filter = TextEditingController();
  final ScrollController _controller = ScrollController();

  static int _selectedUserID = 0;
  String _searchText = "";
  List<User> filteredNames = [];
  List<User> users = [];
  bool isApiCallProcess = false;

  _TalkieUserSearchPageState() {
    _filter.addListener(() {
      if (_filter.text.isEmpty) {
        setState(() {
          _searchText = "";
        });
      } else {
        setState(() {
          _searchText = _filter.text;
        });
      }
    });
  }

  Future<void> _getNames() async {
    setState(() {
      isApiCallProcess = true;
    });
    AdminService service = AdminService();
    UsersResponse result = await service.listTalkieUsers();
    setState(() {
      isApiCallProcess = false;
    });
    if (result.errorMessage.isEmpty) {
      setState(() {
        users = result.users;
      });
    } else {
      showToast(result.errorMessage, ToastificationType.error);
    }
  }

  @override
  void initState() {
    super.initState();
    _getNames();

    _controller.addListener(() {
      FocusScope.of(context).unfocus();
    });
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelectItem(User user) {
    Navigator.of(context).pop();
    widget.onSelectItem(user);
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
      inAsyncCall: isApiCallProcess,
      opacity: 0.3,
      child: _uiSetup(context),
    );
  }

  Scaffold _uiSetup(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Tất cả tài khoản"),
        leading: Container(),
      ),
      body: GestureDetector(
        child: Padding(
          padding: EdgeInsets.all(0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1, color: Colors.grey),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 226, 224, 224),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  height: 42,
                  child: TextFormField(
                    controller: _filter,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Tìm kiếm",
                      prefixIcon: Icon(Icons.search, color: Colors.black),
                      suffixIcon: Visibility(
                        visible: _filter.text.isNotEmpty,
                        child: GestureDetector(
                          onTap: () {
                            _filter.text = "";
                          },
                          child: Icon(Icons.clear, color: Colors.black),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    List<User> list = users;
    List<User> tempList = [];

    String text = "";

    // ignore: prefer_is_not_empty
    if (!_searchText.isEmpty) {
      text = _searchText.searchText;
    }

    for (int i = 0; i < list.length; i++) {
      User user = list[i];
      String userName = nvl(user.userName).searchText;
      String fullName = nvl(user.fullName).searchText;

      if (text.isEmpty || userName.contains(text) || fullName.contains(text)) {
        tempList.add(user);
      }
    }

    filteredNames = tempList;

    return ListView.builder(
      controller: _controller,
      itemCount: filteredNames.length,
      physics: AlwaysScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        User user = filteredNames[index];
        String userName = nvl(user.userName).toUpperCase();
        String fullName = nvl(user.fullName);
        return InkWell(
          onTap: () {
            // print("Click on $index");
            setState(() {
              _selectedUserID = user.userID;
            });
            _onSelectItem(user);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.grey.shade300),
              ),
            ),
            child: ListTile(
              tileColor: (_selectedUserID == user.userID)
                  ? Colors.grey.shade300
                  : null,
              leading: const Icon(Icons.person),
              title: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      userName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text(fullName)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
