

import 'package:chatwithme/model/emailModel.dart';

import 'appState.dart';

//combine reducers
AppState appReducer(AppState state, action) {
  return AppState(
    emailModel: emailreducer(state.emailModel as EmailModel, action),    
    
  );


}

//discoverApi reducer
emailreducer(EmailModel prevState, dynamic action) {
  if (action is EmailModel) {
    return action;
  }
  return prevState;
}
