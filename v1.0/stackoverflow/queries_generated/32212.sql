WITH RecursiveTagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, IsModeratorOnly, IsRequired, 1 AS Level
    FROM Tags
    WHERE Count > 0
    
    UNION ALL
    
    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, t.IsModeratorOnly, t.IsRequired, Level + 1
    FROM Tags t
    INNER JOIN RecursiveTagHierarchy rth ON t.WikiPostId = rth.Id
),
UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, 
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
),
RecentPosts AS (
    SELECT p.Id AS PostId, p.Title, p.CreatedDate, p.Score,
           COUNT(c.Id) AS CommentCount, COUNT(v.Id) AS VoteCount,
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    LEFT JOIN LATERAL STRING_TO_ARRAY(p.Tags, ',') AS tag_names ON TRUE
    LEFT JOIN Tags t ON t.TagName = TRIM(tag_names)
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.Id
),
PostHistoryData AS (
    SELECT ph.PostId, ph.UserId, ph.CreationDate, 
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS PostClosed,
           MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS PostReopened,
           SUM(CASE WHEN ph.PostHistoryTypeId = 24 THEN 1 ELSE 0 END) AS SuggestedEditCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.UserId
),
TagStatistics AS (
    SELECT Id, TagName, 
           SUM(CASE WHEN ph.PostClosed = 1 THEN 1 ELSE 0 END) AS ClosedCount,
           SUM(CASE WHEN ph.PostReopened = 1 THEN 1 ELSE 0 END) AS ReopenedCount,
           AVG(u.Reputation) AS AvgReputation
    FROM Tags t
    JOIN PostHistoryData ph ON t.Id = ph.PostId
    JOIN UserReputation u ON ph.UserId = u.UserId
    GROUP BY t.Id, t.TagName
)
SELECT
    p.PostId,
    p.Title,
    p.CreatedDate,
    p.Score,
    p.CommentCount,
    p.VoteCount,
    t.Tags,
    th.TagName AS TopTag,
    ts.ClosedCount,
    ts.ReopenedCount,
    ts.AvgReputation
FROM RecentPosts p
LEFT JOIN TagStatistics ts ON p.PostId = ts.Id
LEFT JOIN (
    SELECT Id, TagName
    FROM Tags
    ORDER BY Count DESC
    LIMIT 1
) th ON true
WHERE p.CommentCount > 5 AND p.VoteCount > 10
ORDER BY p.Score DESC, ts.ClosedCount DESC;
