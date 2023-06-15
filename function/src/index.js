const {Spanner} = require("@google-cloud/spanner");
const spanner = new Spanner({
    projectId: process.env.PROJECT_ID
});

exports.backup = async (req, res) => {
    const data = req.body ? Buffer.from(req.body, 'base64').toString() : {};
    const event = JSON.parse(data);
    createBackup(event);
    res.status(204).end();
}

const createBackup = async (schedulerEvent) => {
    const instanceId = schedulerEvent.instance_id
    const databaseId = schedulerEvent.database_id;
    const backupId = `${databaseId}-${Date.now()}`;

    const instance = spanner.instance(instanceId);
    const database = instance.database(databaseId);
    const backup = instance.backup(backupId);

    try {
        console.log(`Creating backup of database ${database.formattedName_}.`);
        const databasePath = database.formattedName_;
        const expireTime = Date.now() + schedulerEvent.expire_hours * 60 * 60 * 1000;

        const [, operation] = await backup.create({
            databasePath: databasePath,
            expireTime: expireTime
        });
        console.log(`Waiting for backup ${backup.formattedName_} to complete...`);
        await operation.promise();
        console.log(`Backup "${backup.id}" for "${databaseId}" is now ready for use.`);
    } catch (err) {
        console.error('ERROR:', err);
    } finally {
        await database.close();
    }
}