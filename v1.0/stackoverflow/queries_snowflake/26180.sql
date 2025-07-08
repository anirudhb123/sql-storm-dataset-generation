
WITH StringProcessedData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        ARRAY_SIZE(SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagCount,
        COALESCE((
            SELECT LISTAGG(DISTINCT u.DisplayName, ', ') 
            FROM Users u
            JOIN Posts p2 ON u.Id = p2.OwnerUserId 
            WHERE p2.Id = p.Id
        ), 'No Owner') AS OwnerNames,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS Downvotes
    FROM Posts p
)

SELECT 
    spd.PostId,
    spd.Title,
    spd.TagCount,
    spd.OwnerNames,
    spd.Upvotes,
    spd.Downvotes,
    CASE 
        WHEN spd.Upvotes > spd.Downvotes THEN 'Positive'
        ELSE 'Negative'
    END AS Sentiment,
    LENGTH(spd.Body) AS BodyLength,
    CASE 
        WHEN LENGTH(spd.Body) < 300 THEN 'Short'
        WHEN LENGTH(spd.Body) BETWEEN 300 AND 1500 THEN 'Medium'
        ELSE 'Long'
    END AS BodySizeCategory
FROM StringProcessedData spd
ORDER BY spd.TagCount DESC, spd.Upvotes DESC
LIMIT 50;
