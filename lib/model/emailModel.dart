class EmailModel {
  EmailModel({
    required this.kind,
    required this.idToken,
    required this.email,
    required this.refreshToken,
    required this.expiresIn,
    required this.localId,
  });
  late final String kind;
  late final String idToken;
  late final String email;
  late final String refreshToken;
  late final String expiresIn;
  late final String localId;
  
  EmailModel.fromJson(Map<String, dynamic> json){
    kind = json['kind'];
    idToken = json['idToken'];
    email = json['email'];
    refreshToken = json['refreshToken'];
    expiresIn = json['expiresIn'];
    localId = json['localId'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['kind'] = kind;
    _data['idToken'] = idToken;
    _data['email'] = email;
    _data['refreshToken'] = refreshToken;
    _data['expiresIn'] = expiresIn;
    _data['localId'] = localId;
    return _data;
  }
}