WITH RecursiveTagHierarchy AS (
    SELECT 
        Id AS TagId, 
        TagName, 
        Count, 
        0 AS Level 
    FROM Tags
    WHERE IsModeratorOnly = 0

    UNION ALL

    SELECT 
        t.Id,
        t.TagName,
        t.Count,
        r.Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.ExcerptPostId = r.TagId
),

RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM Posts p
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '30 days'
),

UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
)

SELECT 
    u.DisplayName,
    u.ReputationRank,
    t.TagName,
    COUNT(DISTINCT p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    AVG(COALESCE(c.Score, 0)) AS AverageCommentScore,
    STRING_AGG(DISTINCT c.Text, '; ') AS RecentComments
FROM Users u
LEFT JOIN RecentActivePosts p ON u.Id = p.OwnerUserId
LEFT JOIN Comments c ON p.PostId = c.PostId
LEFT JOIN RecursiveTagHierarchy t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE u.Reputation > 100 -- filtering users with reputation greater than 100
GROUP BY u.Id, u.DisplayName, u.ReputationRank, t.TagName
HAVING COUNT(DISTINCT p.Id) > 2
ORDER BY TotalScore DESC, u.ReputationRank ASC
LIMIT 50;

