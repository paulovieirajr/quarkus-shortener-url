db = db.getSiblingDB('shortener');

db.createUser({
    user: "admin",
    pwd: "admin",
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

db.ShortenedUrl.createIndex(
    { "shortCode": 1 },
    {
        "unique": true,
        "name": "shortcode_unique_index"
    }
);

db.ShortenedUrl.createIndex(
    { "originalUrl": 1 },
    {
        "name": "original_url_index"
    }
);