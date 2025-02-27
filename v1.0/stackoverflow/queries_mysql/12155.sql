
WITH UserReputation AS (
    SELECT Id AS UserId, Reputation
    FROM Users
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
),
TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM Posts p
    CROSS JOIN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag FROM 
        (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag
    JOIN Tags t ON t.TagName = tag
    GROUP BY p.Id
)
SELECT
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.PostType,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    tp.Tags
FROM PostDetails pd
LEFT JOIN TaggedPosts tp ON pd.PostId = tp.PostId
ORDER BY pd.ViewCount DESC
LIMIT 100;
