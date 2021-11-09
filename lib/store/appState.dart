import 'package:chatwithme/model/emailModel.dart';
import 'package:flutter/material.dart';

@immutable
class AppState {
  final EmailModel? emailModel;
  
  AppState(
     { @required this.emailModel}

  );

  factory AppState.initial() => AppState(

      emailModel: EmailModel(email: '', localId: '', refreshToken: '', expiresIn: '', idToken: '', kind: ''),

  );

  AppState copyWith( ) {
    return AppState(
      emailModel: emailModel ?? this.emailModel,

    );
  }
}

