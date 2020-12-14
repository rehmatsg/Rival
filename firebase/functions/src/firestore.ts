import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();

export const newPost = functions.firestore.document('posts/{id}').onCreate( async (snapshot, context) => {
    const data = snapshot.data() ?? '';
    const userRef = db.doc(`users/${data.creator}`);
    const userDoc = await userRef.get();
    const userData = userDoc.data() ?? {};
    
    const taggedPeople : Array<FirebaseFirestore.DocumentReference> = data.people;

    taggedPeople.forEach( async (personRef) => {
        const person = await personRef.get();
        const personData = person.data() ?? {};
        const personToken = personData.token;
        const payload = {
            notification: {
                title: `@${userData.username} tagged you.`,
                body: `${userData.displayName} tagged you in a post`,
                icon: `${data.images[0]}`,
            },
        };
        await admin.messaging().sendToDevice(personToken, payload);
    }); // Send a notification to all tagged people

    if (data.sponsor !== null) {
        const sponsorRef : FirebaseFirestore.DocumentReference = data.sponsor;
        const sponsorDoc = await sponsorRef.get();
        const sponsorData = sponsorDoc.data() ?? {};
        const sponsorToken = sponsorData.token;
        const payload = {
            notification: {
                title: `@${userData.username} added you as a paid partner.`,
                body: `${userData.displayName} added you as a paid partner in a new post.`,
                icon: `${data.images[0]}`,
            },
        };
        await admin.messaging().sendToDevice(sponsorToken, payload);
    }

    const tags : Array<string> = data.tags;
    tags.forEach( async (tag) => {
        await admin.messaging().sendToTopic(tag, {
            notification: {
                title: `New Post for ${tag}`,
                body: `You are recieving this message because you subscribed to ${tag}.`,
                icon: `${data.images[0]}`,
            },
        });
    });

});

export const postUpdate = functions.firestore.document('posts/{id}').onUpdate( async (snapshot, context) => {
    const before = snapshot.before.data();
    const after = snapshot.after.data();

    const ownerRef = db.collection('users').doc(before.creator);
    const ownerDoc = await ownerRef.get();
    const ownerData = ownerDoc.data() ?? {};
    const ownerToken = ownerData.token;

    const bLikes : Map<String, number> = before.likes;
    const aLikes : Map<String, number> = after.likes;

    if (bLikes.keys.length !== aLikes.keys.length) {
        const bLikesArray = Array.from(bLikes.keys());
        const aLikesArray = Array.from(aLikes.keys());
        const newLikes = aLikesArray.filter(item => bLikesArray.indexOf(item) < 0);
        newLikes.forEach( async (userId) => {
            const userRef = db.doc(`users/${userId}`);
            const userDoc = await userRef.get();
            const userData = userDoc.data() ?? {};
            await admin.messaging().sendToDevice(ownerToken, {
                notification: {
                    title: `@${userData.username} liked your post`,
                    body: `${userData.displayName} liked your post`,
                    icon: `${before.images[0]}`,
                },
            });
        });
    }
});

// export const getWeeklyInsights = functions.https.onRequest( async (req, res) => {
//     const userRef = db.collection('users').doc(`${req.query.user}`);
//     const userDoc = await userRef.get();
//     const userData = userDoc.data() ?? {};
//     const userPostsRef : Array<FirebaseFirestore.DocumentReference> = userData['posts'];
//     const startTimestamp = req.query.start;
//     const endTimestamp = req.query.end;

//     const query = await db.collection('posts').where('timestamp', '<=', endTimestamp).where('timestamp', '>=', startTimestamp).where('creator', '==', req.query.user).get();

// });