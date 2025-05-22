db = db.getSiblingDB('shortener');

db.createUser({
    user: "java",
    pwd: "mongodb",
    roles: [
        {
            role: "readWrite",
            db: "shortener"
        }
    ]
});

db.createCollection('ShortenedUrl');

db.ShortenedUrl.createIndex(
    { "expiresAt": 1 },
    {
        "expireAfterSeconds": 0,
        "name": "ttl_index"
    }
);