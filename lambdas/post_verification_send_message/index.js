var aws = require("aws-sdk");
var ses = new aws.SES();

exports.handler = (event, context, callback) => {
  // let adminmail = `Dear ${event.request.userAttributes.given_name},
  //   <br>
  //   <br><br>Your singup process is complete, you can now login to portal using below link.
  //   <br>Your username is ${event.request.userAttributes.given_name}
  //   <br>${process.env.PORTAL_LINK}/login
  //   <br><br>You may also copy and paste the link into your browser to login
  //   <br><br>Thank you,
  //   <br><br>RLCatalyst Research Portal Team`

  // Identify why was this function invoked
  if ("custom:created_by" in event.request.userAttributes) {
    let body = `Your Research Gateway account username is ${event.userName}`;
    sendEmail(event.request.userAttributes.email, body, function (status) {
      // Return to Amazon Cognito
      callback(null, event);
    });
  } else {
    // Return to Amazon Cognito
    callback(null, event);
  }
};

function sendEmail(to, body, completedCallback) {
  var eParams = {
    Destination: {
      ToAddresses: [to],
    },
    Message: {
      Body: {
        Text: {
          Data: body,
        },
      },
      Subject: {
        Data: "Research Gateway account verification successful",
      },
    },

    // Replace source_email with your SES validated email address
    Source: "rlc.support@relevancelab.com",
  };

  var email = ses.sendEmail(eParams, function (err, data) {
    if (err) {
      console.log(err);
    } else {
      console.log("===EMAIL SENT===");
    }
    completedCallback("Email sent");
  });
  console.log("EMAIL CODE END");
}
