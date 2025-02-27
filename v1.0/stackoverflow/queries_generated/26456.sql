WITH RankedPosts AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.Tags,
           p.CreationDate,
           p.ViewCount,
           p.Score, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Ranking
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only considering Questions
      AND p.Score > 0
),
TagCounts AS (
    SELECT unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag, 
           COUNT(*) AS CountTags
    FROM Posts
    WHERE PostTypeId = 1
    GROUP BY Tag
),
UserReputation AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           SUM(VOTE_COUNT) AS TotalVotes,
           AVG(u.Reputation) AS AvgReputation
    FROM Users u
    JOIN (
        SELECT v.UserId, 
               COUNT(*) AS VOTE_COUNT
        FROM Votes v
        INNER JOIN Posts p ON v.PostId = p.Id
        WHERE p.OwnerUserId IS NOT NULL 
        GROUP BY v.UserId
    ) AS userVotes ON u.Id = userVotes.UserId
    GROUP BY u.Id
)
SELECT r.PostId,
       r.Title,
       r.CreationDate,
       r.ViewCount,
       rt.Tag,
       rt.CountTags,
       ur.DisplayName AS TopUser,
       ur.TotalVotes,
       ur.AvgReputation
FROM RankedPosts r
JOIN TagCounts rt ON rt.Tag = ANY(string_to_array(substring(r.Tags, 2, length(r.Tags)-2), '><'))
JOIN UserReputation ur ON ur.UserId = r.OwnerUserId
WHERE r.Ranking <= 3 -- Get top 3 questions per user
ORDER BY r.OwnerUserId, r.Score DESC;
