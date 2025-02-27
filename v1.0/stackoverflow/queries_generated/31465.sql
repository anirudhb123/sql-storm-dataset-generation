WITH RecentUsers AS (
    SELECT Id, DisplayName, Reputation,
           ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS UserRank
    FROM Users
    WHERE LastAccessDate > NOW() - INTERVAL '1 year'
),
TopTags AS (
    SELECT TagName, COUNT(*) AS UsageCount
    FROM Posts
    WHERE Tags IS NOT NULL
    GROUP BY TagName
    HAVING COUNT(*) > 10
),
PostMetrics AS (
    SELECT p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate,
           COALESCE(CAST(p.Body AS TEXT), 'No content') AS BodyExcerpt,
           (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
           DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT ph.PostId, ph.CreationDate AS CloseDate, COUNT(ph.Id) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
    GROUP BY ph.PostId, ph.CreationDate
),
RecursiveVoteCount AS RECURSIVE (
    SELECT PostId, COUNT(*) AS TotalVotes
    FROM Votes
    WHERE CreationDate > NOW() - INTERVAL '1 month'
    GROUP BY PostId
    UNION ALL
    SELECT v.PostId, rc.TotalVotes + COUNT(v.Id)
    FROM Votes v
    INNER JOIN RecursiveVoteCount rc ON v.PostId = rc.PostId
    WHERE v.CreationDate <= NOW() - INTERVAL '1 month'
    GROUP BY v.PostId
)
SELECT u.DisplayName AS RecentUser,
       t.TagName AS PopularTag,
       p.Title AS PostTitle,
       pm.ViewCount,
       pm.Score,
       cp.CloseDate,
       COALESCE(rv.TotalVotes, 0) AS RecentVoteCount,
       CASE 
           WHEN cp.CloseCount > 0 THEN 'Closed'
           ELSE 'Open'
       END AS PostStatus
FROM RecentUsers u
CROSS JOIN TopTags t
JOIN PostMetrics pm ON pm.ViewCount > 100
LEFT JOIN ClosedPosts cp ON pm.Id = cp.PostId
LEFT JOIN RecursiveVoteCount rv ON pm.Id = rv.PostId
WHERE u.UserRank <= 10
ORDER BY u.Reputation DESC, t.UsageCount DESC, pm.Score DESC;
