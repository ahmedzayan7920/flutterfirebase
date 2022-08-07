import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../components/awesome_dialog.dart';
import '../components/loading_dialog.dart';

class EditNotes extends StatefulWidget {
  const EditNotes({Key? key, required this.noteData, required this.docId})
      : super(key: key);

  final Map<String, dynamic> noteData;
  final String docId;

  @override
  State<EditNotes> createState() => _EditNotesState();
}

class _EditNotesState extends State<EditNotes> {
  late Reference ref;

  File? file;
  late String title, note;
  bool withImage = false;
  var notesRef = FirebaseFirestore.instance.collection("notes");

  GlobalKey<FormState> formState = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: formState,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Without Image"),
                  Switch(
                    value: withImage,
                    onChanged: (newVal) {
                      setState(() {
                        withImage = newVal;
                      });
                    },
                  ),
                  const Text("With Image"),
                ],
              ),
              withImage
                  ? GestureDetector(
                      onTap: () {
                        showBottomSheet(context);
                      },
                      child: file != null
                          ? Image.file(
                              file!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.fitHeight,
                            )
                          : widget.noteData["imageUrl"] != ""
                              ? Image.network(
                                  widget.noteData["imageUrl"],
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.fitHeight,
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  size: 150,
                                ),
                    )
                  : const SizedBox.shrink(),
              TextFormField(
                initialValue: title,
                validator: (val) {
                  if (val!.length > 30) {
                    return "Title can't to be larger than 30 letter";
                  }
                  if (val.length < 2) {
                    return "Title can't to be less than 2 letter";
                  }
                  return null;
                },
                onSaved: (val) {
                  title = val!;
                },
                maxLength: 30,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.note),
                  label: Text("Title Note"),
                ),
              ),
              TextFormField(
                initialValue: note,
                validator: (val) {
                  if (val!.length > 255) {
                    return "Notes can't to be larger than 255 letter";
                  }
                  if (val.length < 10) {
                    return "Notes can't to be less than 10 letter";
                  }
                  return null;
                },
                onSaved: (val) {
                  note = val!;
                },
                minLines: 1,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: "Note",
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool oldImage =
                      widget.noteData["imageUrl"] == "" ? false : true;
                  await editNotes(context, oldImage);
                },
                child: Text(
                  "Edit Note",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      title = widget.noteData["title"];
      note = widget.noteData["note"];
      withImage = widget.noteData["imageUrl"] == "" ? false : true;
    });
  }

  editNotes(context, oldImage) async {
    var formData = formState.currentState;
    if (formData!.validate()) {
      formData.save();
      showLoadingDialog(context);
      if (withImage) {
        if (file == null) {
          Navigator.pop(context);
          return showAwesomeDialog(context, "please choose Image");
        } else {
          await ref.putFile(file!).then((p0) {
            ref.getDownloadURL().then((value) {
              if (oldImage) {
                FirebaseStorage.instance
                    .refFromURL(widget.noteData["imageUrl"])
                    .delete()
                    .then((val) {
                  notesRef.doc(widget.docId).update({
                    "title": title,
                    "note": note,
                    "imageUrl": value,
                  }).then((value) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }).catchError((e) {
                    Navigator.pop(context);
                    showAwesomeDialog(context, e.toString());
                  });
                }).catchError((e) {
                  Navigator.pop(context);
                  showAwesomeDialog(context, e.toString());
                });
              } else {
                notesRef.doc(widget.docId).update({
                  "title": title,
                  "note": note,
                  "imageUrl": value,
                }).then((value) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }).catchError((e) {
                  Navigator.pop(context);
                  showAwesomeDialog(context, e.toString());
                });
              }
            }).catchError((e) {
              Navigator.pop(context);
              showAwesomeDialog(context, e.toString());
            });
          }).catchError((e) {
            Navigator.pop(context);
            showAwesomeDialog(context, e.toString());
          });
        }
      } else {
        if (oldImage) {
          FirebaseStorage.instance
              .refFromURL(widget.noteData["imageUrl"])
              .delete()
              .then((val) {
            notesRef.doc(widget.docId).update({
              "title": title,
              "note": note,
              "imageUrl": "",
            }).then((value) {
              Navigator.pop(context);
              Navigator.pop(context);
            }).catchError((e) {
              Navigator.pop(context);
              showAwesomeDialog(context, e.toString());
            });
          }).catchError((e) {
            Navigator.pop(context);
            showAwesomeDialog(context, e.toString());
          });
        } else {
          notesRef.doc(widget.docId).update({
            "title": title,
            "note": note,
            "imageUrl": "",
          }).then((value) {
            Navigator.pop(context);
            Navigator.pop(context);
          }).catchError((e) {
            Navigator.pop(context);
            showAwesomeDialog(context, e.toString());
          });
        }
      }
    }
  }

  showBottomSheet(context) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Please Choose Image",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ImagePicker()
                        .pickImage(source: ImageSource.gallery)
                        .then((value) {
                      setState(() {
                        file = File(value!.path);
                      });
                      var rand = Random().nextInt(100000);
                      var imageName = "$rand${basename(value!.path)}";
                      ref = FirebaseStorage.instance
                          .ref("images")
                          .child("notes")
                          .child(imageName);
                    }).catchError((e) {
                      showAwesomeDialog(context, e.toString());
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.photo_outlined,
                          size: 30,
                        ),
                        SizedBox(width: 20),
                        Text(
                          "From Gallery",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    ImagePicker()
                        .pickImage(source: ImageSource.camera)
                        .then((value) {
                      setState(() {
                        file = File(value!.path);
                      });
                      var rand = Random().nextInt(100000);
                      var imageName = "$rand${basename(value!.path)}";
                      ref = FirebaseStorage.instance
                          .ref("images")
                          .child("notes")
                          .child(imageName);
                    }).catchError((e) {
                      showAwesomeDialog(context, e.toString());
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.camera,
                          size: 30,
                        ),
                        SizedBox(width: 20),
                        Text(
                          "From Camera",
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
