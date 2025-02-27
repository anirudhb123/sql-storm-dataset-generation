
WITH PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.Reputation AS OwnerReputation,
        t.TagName
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        (SELECT p.Id, SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName 
         FROM Posts p 
         JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(p.Tags) 
         - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= n.n - 1) t ON p.Id = t.Id
)

SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerReputation,
    COUNT(pd.TagName) AS TagCount
FROM
    PostDetails pd
GROUP BY
    pd.PostId, pd.Title, pd.CreationDate, pd.ViewCount, pd.Score, pd.OwnerReputation
ORDER BY
    pd.Score DESC, pd.ViewCount DESC;
