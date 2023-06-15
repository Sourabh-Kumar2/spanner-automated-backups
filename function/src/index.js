const {Spanner} = require("@google-cloud/spanner");
const spanner = new Spanner({
    projectId: process.env.PROJECT_ID
});

exports.backup = async (req, res) => {
    const data = req.body ? Buffer.from(req.body, 'base64').toString() : {};
    const event = JSON.parse(data);
    await createBackup(event);
    res.status(204).end();
}

const createBackup = async (event) => {
    const backupId = `${event.database}-${Date.now()}`;
    const instance = spanner.instance(event.instance);
    const database = instance.database(event.database);
    const backup = instance.backup(backupId);

    try {
        const expireTime = Date.now() + event.expire * 60 * 60 * 1000;
        const [, operation] = await backup.create({
            databasePath: database.formattedName_,
            expireTime: expireTime
        });
        console.log(`Waiting for backup ${backup.formattedName_} to complete...`);
        await operation.promise();
        console.log(`Backup ${backup.formattedName_} for ${event.database} is completed.`);
    } catch (err) {
        console.error('ERROR:', err);
    } finally {
        await database.close();
    }
}