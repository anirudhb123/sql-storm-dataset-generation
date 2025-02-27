WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired, 
           CAST(TagName AS VARCHAR(500)) AS FullTagPath
    FROM Tags
    WHERE ParentTagId IS NULL  -- Assuming there might be a ParentTag field for hierarchy

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired,
           CAST(CONCAT(r.FullTagPath, ' > ', t.TagName) AS VARCHAR(500))
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy r ON t.ParentTagId = r.Id
),
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           COUNT(v.Id) AS VoteCount, 
           STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL (SELECT UNNEST(string_to_array(p.Tags, '><')) AS TagName) AS tm ON true
    LEFT JOIN Tags t ON tm.TagName = t.TagName
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserActivityStats AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           SUM(CASE WHEN p.OwnerUserId = u.Id THEN 1 ELSE 0 END) AS PostCount,
           SUM(CASE WHEN c.UserId = u.Id THEN 1 ELSE 0 END) AS CommentCount,
           SUM(CASE WHEN b.UserId = u.Id THEN 1 ELSE 0 END) AS BadgeCount,
           MAX(u.CreationDate) AS AccountCreationDate,
           COUNT(DISTINCT p.Id) FILTER (WHERE p.Score > 0) AS HighScoredPosts
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
)
SELECT u.DisplayName, u.PostCount, u.CommentCount, u.BadgeCount, u.HighScoredPosts, 
       pt.PostId, pt.Title, pt.Score, pt.ViewCount, pt.VoteCount, 
       rth.FullTagPath AS TagHierarchy
FROM UserActivityStats u
JOIN PostDetails pt ON u.PostCount > 0
LEFT JOIN RecursiveTagHierarchy rth ON rth.TagName IN (SELECT UNNEST(string_to_array(pt.TagsUsed, ', ')))
WHERE u.CommentCount > 10
ORDER BY u.BadgeCount DESC, pt.Score DESC
LIMIT 100;

-- This query combines several advanced SQL features including CTEs for recursive tag handling,
-- complex aggregations, conditional counting, string manipulation, and joins to fetch relevant data
-- for users with significant activity on Stack Overflow posts.
