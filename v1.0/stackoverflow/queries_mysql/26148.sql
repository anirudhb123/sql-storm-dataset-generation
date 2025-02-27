
WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.Tags,
           p.CreationDate,
           p.Score,
           u.Reputation AS OwnerReputation,
           ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  
),
RecentPosts AS (
    SELECT PostId,
           Title,
           Body,
           Tags,
           CreationDate,
           Score,
           OwnerReputation
    FROM RankedPosts
    WHERE TagRank <= 5  
    AND CreationDate >= NOW() - INTERVAL 30 DAY
),
TagStatistics AS (
    SELECT TagName,
           COUNT(DISTINCT PostId) AS PostCount,
           AVG(OwnerReputation) AS AvgReputation,
           MAX(CreationDate) AS LatestPostDate
    FROM RecentPosts
    JOIN (
        SELECT PostId, SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName
        FROM RecentPosts
        INNER JOIN (
            SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    ) AS TagsTable ON RecentPosts.PostId = TagsTable.PostId
    GROUP BY TagName
)
SELECT ts.TagName,
       ts.PostCount,
       ts.AvgReputation,
       ts.LatestPostDate,
       GROUP_CONCAT(rp.Title SEPARATOR '; ') AS TopTitles,
       GROUP_CONCAT(rp.Body SEPARATOR '; ') AS TopBodies
FROM TagStatistics ts
JOIN RecentPosts rp ON FIND_IN_SET(ts.TagName, REPLACE(rp.Tags, '><', ',')) > 0
GROUP BY ts.TagName, ts.PostCount, ts.AvgReputation, ts.LatestPostDate
ORDER BY ts.PostCount DESC, ts.AvgReputation DESC;
