const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require('firebase-admin');
const logger = require("firebase-functions/logger");

admin.initializeApp();

// exports.clearTodayHistory = onSchedule('0 0 * * *', {
//   timeZone: 'Asia/Jerusalem',
//   retryCount: 3,
//   memory: '256MiB'
//  // maxRetrySeconds: 60
// }, async (event) => {
//   try {
//     const doorbellsSnapshot = await admin.firestore()
//       .collection('doorbells')
//       .get();

//     const batch = admin.firestore().batch();
    
//     for (const doorbell of doorbellsSnapshot.docs) {
//       const todayHistorySnapshot = await doorbell.ref
//         .collection('today_history')
//         .get();

//       todayHistorySnapshot.docs.forEach((doc) => {
//         batch.delete(doc.ref);
//       });
//     }

//     await batch.commit();
//     logger.info('Today history cleared successfully');
//     return null;
//   } catch (error) {
//     logger.error('Error clearing today history:', error);
//     return null;
//   }
// });


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

exports.autoDeclineAfterTimeout = onDocumentUpdated({
    document: 'doorbells/{doorbellId}',
    region: 'us-central1'
  }, async (event) => {
    const beforeData = event.data.before;
    const afterData = event.data.after;
    const afterDataObj = afterData.data();
    const beforeDataObj = beforeData.data();
    
    // Check if state changed to 1
    if (afterDataObj?.doorbellState === 1 && beforeDataObj?.doorbellState !== 1) {
      // Use async/await with Promise
      await new Promise(resolve => setTimeout(resolve, 60000)); // 60 seconds

      // Check current state
      const currentDoc = await afterData.ref.get();
      const currentState = currentDoc.data()?.doorbellState;
      const imageURL = currentDoc.data()?.imageURL;
      
      // If still in state 1 after 60 seconds
      if (currentState === 1) {
        // Create today_history document first
        if (imageURL) {
          await afterData.ref.collection('today_history').add({
            date: admin.firestore.FieldValue.serverTimestamp(),
            imageURL: imageURL
          });
        }

        // Then update doorbell state
        await afterData.ref.update({
          doorbellState: 4,
          message: 'Auto-denied due to no response'
        });
        
        logger.info(`Doorbell ${event.params.doorbellId} auto-denied after timeout`);
      }
    }
    return null;
});