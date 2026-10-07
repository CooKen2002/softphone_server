import 'package:flutter/material.dart';
import '../models/soft_phone_model.dart';

class ContactDetail extends StatefulWidget {
  const ContactDetail({super.key, required this.contact});
  final CallLog contact;

  @override
  State<ContactDetail> createState() => _ContactDetailState();
}

class _ContactDetailState extends State<ContactDetail> {
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  String parseNumber(String? num) {
    if (num == null) return "";
    return num.split("@")[0];
  }

  @override
  void initState() {
    super.initState();
    phoneNoController.text = parseNumber(widget.contact.getPhoneNo());
    nameController.text = widget.contact.getPhoneName();
  }

  @override
  void dispose() {
    phoneNoController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Thông tin liên hệ"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextFormField(
            "Tên khách hàng",
            "",
            Icons.person,
            nameController,
          ),

          SizedBox(height: 10),
          _buildTextFormField(
            "Số điện thoại",
            "1630",
            Icons.phone,
            phoneNoController,
            readOnly: true,
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("Lưu"),
          onPressed: () {
            CallLog ch = widget.contact;
            ch.setPhoneName(nameController.text);
            ch.fullName = nameController.text;
            Navigator.of(context).pop(ch);
          },
        ),
        TextButton(
          child: const Text("Hủy bỏ"),
          onPressed: () {
            Navigator.of(context).pop(null);
          },
        ),
      ],
    );
  }

  Widget _buildTextFormField(
    String labelText,
    String hintText,
    IconData icon,
    TextEditingController controller, {
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: readOnly,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
