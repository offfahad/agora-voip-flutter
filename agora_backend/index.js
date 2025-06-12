const express = require('express');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
const dotenv = require('dotenv');
const cors = require('cors');
dotenv.config();

const app = express();
app.use(express.json());
app.use(cors()); 

const APP_ID = process.env.AGORA_APP_ID;
const APP_CERTIFICATE = process.env.AGORA_APP_CERTIFICATE;

const TOKEN_EXPIRATION = 7200; // 2 hours
const PRIVILEGE_EXPIRATION = 7200; // Match privilege expiration

// Validate environment variables
if (!APP_ID || !APP_CERTIFICATE) {
  console.error('Error: AGORA_APP_ID and AGORA_APP_CERTIFICATE must be set in .env file');
  process.exit(1);
}

// Endpoint to generate Agora RTC token
app.post('/generate-token', (req, res) => {
  try {
    const { channelName, uid } = req.body;

    // Validate input
    if (!channelName || !uid) {
      return res.status(400).json({
        error: 'Missing required parameters: channelName and uid are required',
      });
    }

    // Get current timestamp and add buffer
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + PRIVILEGE_EXPIRATION;

    // Generate token
    const token = RtcTokenBuilder.buildTokenWithUid(
      APP_ID,
      APP_CERTIFICATE,
      channelName,
      parseInt(uid, 10),
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    console.log(`Generated token for channel: ${channelName}, uid: ${uid}`);

    // Return token
    res.status(200).json({
      token,
      appId: APP_ID,
      channelName,
      uid,
      privilegeExpiredTs,
    });
  } catch (error) {
    console.error(`Error generating token for channel: ${req.body.channelName}, uid: ${req.body.uid}`, error);
    res.status(500).json({
      error: 'Failed to generate token',
      details: error.message,
    });
  }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});