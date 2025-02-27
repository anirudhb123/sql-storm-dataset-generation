
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
    AND CreationDate >= DATEADD(day, -30, '2024-10-01 12:34:56')
),
TagStatistics AS (
    SELECT TagName,
           COUNT(DISTINCT PostId) AS PostCount,
           AVG(OwnerReputation) AS AvgReputation,
           MAX(CreationDate) AS LatestPostDate
    FROM RecentPosts
    CROSS APPLY STRING_SPLIT(Tags, '><') AS TagName
    GROUP BY TagName
)
SELECT ts.TagName,
       ts.PostCount,
       ts.AvgReputation,
       ts.LatestPostDate,
       STRING_AGG(rp.Title, '; ') AS TopTitles,
       STRING_AGG(rp.Body, '; ') AS TopBodies
FROM TagStatistics ts
JOIN RecentPosts rp ON ts.TagName IN (SELECT value FROM STRING_SPLIT(rp.Tags, '><'))
GROUP BY ts.TagName, ts.PostCount, ts.AvgReputation, ts.LatestPostDate
ORDER BY ts.PostCount DESC, ts.AvgReputation DESC;
