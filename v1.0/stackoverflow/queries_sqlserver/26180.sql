
WITH StringProcessedData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        LEN(substring(p.Tags, 2, LEN(p.Tags)-2)) - LEN(REPLACE(substring(p.Tags, 2, LEN(p.Tags)-2), '><', '')) + 1 AS TagCount,
        COALESCE((
            SELECT STRING_AGG(DISTINCT u.DisplayName, ', ') 
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
    LEN(spd.Body) AS BodyLength,
    CASE 
        WHEN LEN(spd.Body) < 300 THEN 'Short'
        WHEN LEN(spd.Body) BETWEEN 300 AND 1500 THEN 'Medium'
        ELSE 'Long'
    END AS BodySizeCategory
FROM StringProcessedData spd
GROUP BY 
    spd.PostId,
    spd.Title,
    spd.TagCount,
    spd.OwnerNames,
    spd.Upvotes,
    spd.Downvotes,
    spd.Body
ORDER BY spd.TagCount DESC, spd.Upvotes DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
