const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
//const functions = require("firebase-functions");
const admin = require('firebase-admin');
const logger = require("firebase-functions/logger");
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});


////////////////////////////////////////////////////////////////
// clear today history every day at midnight
///////////////////////////////////////////////////////////////

//512MiB
exports.clearTodayHistory = onSchedule({
  schedule: '0 0 * * *',
  timeZone: 'Asia/Jerusalem',
  retryConfig: {
    maxRetryAttempts: 3,
    minBackoffDuration: '1m'
  },
  memory: '1GiB',
  timeoutSeconds: 120,
  region: 'us-central1',
  //serviceAccount: 'firebase-adminsdk-service-account@my-smart-doorbell-f6458.iam.gserviceaccount.com'
}, async (event) => {
  try {
    logger.info('Starting clearTodayHistory function');
    
    const db = admin.firestore();
    const doorbellsRef = db.collection('doorbells');
    
    const doorbellsSnapshot = await doorbellsRef.get();
    logger.info(`Found ${doorbellsSnapshot.size} doorbells`);
    
    const batch = db.batch();
    let count = 0;

    for (const doorbell of doorbellsSnapshot.docs) {
      const historyRef = doorbell.ref.collection('today_history');
      const historyDocs = await historyRef.get();
      
      historyDocs.forEach(doc => {
        batch.delete(doc.ref);
        count++;
      });
    }

    await batch.commit();
    logger.info(`Cleared ${count} history documents`);
    return {success: true, count};

  } catch (error) {
    logger.error('Failed to clear history:', error);
    throw new Error('Failed to clear history: ' + error.message);
  }
});



//////////////////////////////////////////////////////////////////
//auto decline doorbell after 60 seconds
/////////////////////////////////////////////////////////////////


// Set timestamp when state changes to 1
//used if i want to use the checkAutoDecline function again
exports.setRingTimestamp = onDocumentUpdated({
  document: 'doorbells/{doorbellId}',
  region: 'us-central1'
}, async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  
  if (afterData?.doorbellState === 1 && beforeData?.doorbellState !== 1) {
    logger.info(`Setting timestamp for doorbell ${event.params.doorbellId}`);
    await event.data.after.ref.update({
      ringTimestamp: admin.firestore.FieldValue.serverTimestamp()
    });
  }
});

//this is used when doorbell state changes to 1, it will wait 60 seconds and then check if the state is still 1,
//  if it is then it will auto decline the doorbell (doorbellstate 4) and reset the state to 0 after 6 seconds. 
exports.handleDoorbellState4 = onDocumentUpdated({
  document: 'doorbells/{doorbellId}',
  region: 'us-central1'
}, async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const db = admin.firestore();
  
  // When state changes to 1, start 60s timer
  if (afterData?.doorbellState === 1 && beforeData?.doorbellState !== 1) {
    logger.info(`Doorbell ${event.params.doorbellId} rang - starting 60s timer`);
    
    // Wait 60 seconds
     await new Promise(resolve => setTimeout(resolve, 60000));
    
    // Check if still in state 1
    const currentDoc = await event.data.after.ref.get();
    const currentState = currentDoc.data()?.doorbellState;
    
    if (currentState === 1) {
      // Auto-decline
      const data = currentDoc.data();
      const batch = db.batch();
      
      if (data.imageURL) {
        const historyRef = currentDoc.ref.collection('today_history').doc();
        batch.set(historyRef, {
          date: admin.firestore.FieldValue.serverTimestamp(),
          imageURL: data.imageURL
        });
      }
      
      batch.update(currentDoc.ref, {
        doorbellState: 4,
        message: 'Auto-denied due to no response',
        autoResetTimestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      
      await batch.commit();
      logger.info(`Auto-declined doorbell ${event.params.doorbellId}`);
      
      // Wait 6 seconds then reset to state 0
      await new Promise(resolve => setTimeout(resolve, 6000));
      
      await currentDoc.ref.update({
        doorbellState: 0,
        message: '',
        autoResetTimestamp: null
      });
      
      logger.info(`Reset doorbell ${event.params.doorbellId} to state 0`);
    }
  }
  return null;
});

// exports.autoDeclineAfterTimeout = onDocumentUpdated({
//     document: 'doorbells/{doorbellId}',
//     region: 'us-central1'
//   }, async (event) => {
//     const beforeData = event.data.before;
//     const afterData = event.data.after;
//     const afterDataObj = afterData.data();
//     const beforeDataObj = beforeData.data();
    
//     // Check if state changed to 1
//     if (afterDataObj?.doorbellState === 1 && beforeDataObj?.doorbellState !== 1) {
//       // Use async/await with Promise
//       await new Promise(resolve => setTimeout(resolve, 60000)); // 60 seconds

//       // Check current state
//       const currentDoc = await afterData.ref.get();
//       const currentState = currentDoc.data()?.doorbellState;
//       const imageURL = currentDoc.data()?.imageURL;
      
//       // If still in state 1 after 60 seconds
//       if (currentState === 1) {
//         // Create today_history document first
//         if (imageURL) {
//           await afterData.ref.collection('today_history').add({
//             date: admin.firestore.FieldValue.serverTimestamp(),
//             imageURL: imageURL
//           });
//         }

//         // Then update doorbell state
//         await afterData.ref.update({
//           doorbellState: 4,
//           message: 'Auto-denied due to no response'
//         });
        
//         logger.info(`Doorbell ${event.params.doorbellId} auto-denied after timeout`);
//       }
//     }
//     return null;
// });


// exports.checkAutoDecline = onSchedule({
//   schedule: "every 1 minutes",
//   region: "us-central1",
//   memory: "256MiB",
//   timeoutSeconds: 30
// }, async (context) => {
//   try {
//     const db = admin.firestore();
//     const now = admin.firestore.Timestamp.now();
    
//     // First check for state 4 to reset to 0
//     const resetQuery = await db.collection('doorbells')
//       .where('doorbellState', '==', 4)
//       .where('autoResetTimestamp', '<', 
//         admin.firestore.Timestamp.fromMillis(now.toMillis() - 6000))  // 6 seconds
//       .get();

//     if (!resetQuery.empty) {
//       const resetBatch = db.batch();
//       resetQuery.docs.forEach(doc => {
//         resetBatch.update(doc.ref, {
//           doorbellState: 0,
//           message: '',
//           autoResetTimestamp: null
//         });
//       });
//       await resetBatch.commit();
//       logger.info(`Reset ${resetQuery.size} doorbells to state 0`);
//     }

//     // Then check for state 1 to auto-decline
//     const timeoutThreshold = admin.firestore.Timestamp.fromMillis(now.toMillis() - 60000);
//     const declineQuery = await db.collection('doorbells')
//       .where('doorbellState', '==', 1)
//       .where('ringTimestamp', '<', timeoutThreshold)
//       .get();

//     if (!declineQuery.empty) {
//       const declineBatch = db.batch();
//       declineQuery.docs.forEach(doc => {
//         const data = doc.data();
//         if (data.imageURL) {
//           const historyRef = doc.ref.collection('today_history').doc();
//           declineBatch.set(historyRef, {
//             date: now,
//             imageURL: data.imageURL
//           });
//         }
//         declineBatch.update(doc.ref, {
//           doorbellState: 4,
//           message: 'Auto-denied due to no response',
//           ringTimestamp: null,
//           autoResetTimestamp: admin.firestore.FieldValue.serverTimestamp()
//         });
//       });
//       await declineBatch.commit();
//       logger.info(`Auto-declined ${declineQuery.size} doorbells`);
//     }

//   } catch (error) {
//     logger.error('Auto-decline error:', error);
//     throw error;
//   }
// });

///////////////////////////////////////////////////////////////
//change doorbell state from 2 or 3 to 0 after 6 seconds
//////////////////////////////////////////////////////////////

//this is used when doorbell state changes to 2 or 3, it will wait 3 seconds and then reset the state to 0
exports.handleStates2And3 = onDocumentUpdated({
  document: 'doorbells/{doorbellId}',
  region: 'us-central1'
}, async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  
  // Check if state changed to 2 or 3
  if ((afterData?.doorbellState === 2 || afterData?.doorbellState === 3) && 
      (beforeData?.doorbellState !== 2 && beforeData?.doorbellState !== 3)) {
    
    logger.info(`Doorbell ${event.params.doorbellId} state changed to ${afterData.doorbellState} - starting 7s timer`);
    
    // Wait 6 seconds
    await new Promise(resolve => setTimeout(resolve, 6000));
    
    // Reset state to 0
    await event.data.after.ref.update({
      doorbellState: 0,
      message: ''
    });
    
    logger.info(`Reset doorbell ${event.params.doorbellId} to state 0`);
  }
  return null;
});




////////////////////////////////////////////////////
//sendDoorbellNotification
///////////////////////////////////////////////////

exports.sendDoorbellNotification = onDocumentUpdated({
  document: 'doorbells/{doorbellId}',
  region: 'us-central1'
}, async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  
  if (afterData?.doorbellState === 1 && beforeData?.doorbellState !== 1) {
    const topic = `doorbell_${event.params.doorbellId}`;
    
    try {
      const message = {
        topic: topic,
        notification: {
          title: 'Doorbell Alert!',
          body: 'Someone is at your door!'
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'doorbell_channel',
            priority: 'max',
            sound: 'default',
            tag: 'doorbell_notification' // Add this to prevent duplicates
          }
        }
      };

      await admin.messaging().send(message);
      logger.info(`Notification sent to topic: ${topic}`);
      return null;
    } catch (error) {
      logger.error('Error sending notification:', error);
      return null;
    }
  }
  return null;
});