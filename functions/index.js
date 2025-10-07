const functions = require("firebase-functions");
const nodemailer = require("nodemailer");

exports.sendResetCode = functions.https.onCall(async (data, context) => {
  console.log("Function triggered with data:", data);

  const email = data.email;
  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email required');
  }

  const resetCode = Math.floor(100000 + Math.random() * 900000).toString();

  // ✅ Configure Gmail transporter
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: "jamiencharisse@gmail.com",
      pass: "urzgnpklgozkeyiq",
    },
  });

  const mailOptions = {
    from: "YOUR_EMAIL@gmail.com",
    to: email,
    subject: "Zapac Password Reset Code",
    text: `Your password reset code is: ${resetCode}`,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log("Reset code sent successfully to:", email);
    return { success: true, code: resetCode };
  } catch (error) {
    console.error("Error sending email:", error);
    throw new functions.https.HttpsError("internal", "Error sending email");
  }
});
