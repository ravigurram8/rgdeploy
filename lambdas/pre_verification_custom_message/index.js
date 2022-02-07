exports.handler = (event, _context, callback) => {
  let resetPassmail = `Dear ${event.request.userAttributes.name},
      <br>
      <br><br>You are one step away from resetting your password for RLCatalyst Research Gateway.
      <br>To reset your password please click the link
      <br>${process.env.PORTAL_LINK}/reset-password?user=${event.request.userAttributes.given_name}&code=${event.request.codeParameter}
      <br><br>You may also copy and paste the link into your browser to complete the process.If you did not make this request, please ignore this message.
      <br><br>Thank you,
      <br><br>RLCatalyst Research Gateway Team`;

  let mail = `Dear ${event.request.userAttributes.name},
      <br>
      <br><br>You are one step away from completing your registration to RLcatalyst Research Portal.
      <br>To activate your account please click the link
      <br>${process.env.PORTAL_LINK}/verify?user=${event.request.userAttributes.given_name}&code=${event.request.codeParameter}
      <br><br>You may also copy and paste the link into your browser to complete the process.
      <br><br>Thank you,
      <br><br>RLCatalyst Research Gateway Team`;

  let adminmail = `Dear ${event.request.userAttributes.name},
      <br>
      <br><br>Your administrator has added you as a user in the RLCatalyst Research Gateway. Please complete the activation process below.
      <br>To activate your account please click the link
      <br>${process.env.PORTAL_LINK}/reset-password?id=${event.request.userAttributes["custom:user"]}&code=${event.request.codeParameter}
      <br><br>You may also copy and paste the link into your browser to complete the process.
      <br><br>Thank you,
      <br><br>RLCatalyst Research Gateway Team`;

  console.log(JSON.stringify(event.request));
  // Identify why was this function invoked
  if (event.triggerSource === "CustomMessage_ForgotPassword") {
    event.response.smsMessage =
      "Your confirmation code is: " + event.request.codeParameter;
    event.response.emailSubject =
      "RLCatalyst Research Gateway: Your request to reset password";
    event.response.emailMessage = resetPassmail;
  }

  if (
    event.triggerSource === "CustomMessage_SignUp" ||
    event.triggerSource === "CustomMessage_ResendCode"
  ) {
    if ("custom:created_by" in event.request.userAttributes) {
      event.response.smsMessage =
        "Your confirmation code is: " + event.request.codeParameter;
      event.response.emailSubject =
        "RLCatalyst Research Gateway verification link";
      event.response.emailMessage = adminmail;
    } else {
      event.response.smsMessage =
        "Your confirmation code is: " + event.request.codeParameter;
      event.response.emailSubject =
        "RLCatalyst Research Gateway verification link";
      event.response.emailMessage = mail;
    }
  }

  // Return to Amazon Cognito
  callback(null, event);
};
