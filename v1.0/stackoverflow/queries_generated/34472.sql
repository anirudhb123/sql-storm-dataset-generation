WITH RECURSIVE TagHierarchy AS (
    SELECT Id, TagName, Count, ExcerptPostId, WikiPostId, 1 AS Level
    FROM Tags
    WHERE IsRequired = 1

    UNION ALL

    SELECT t.Id, t.TagName, t.Count, t.ExcerptPostId, t.WikiPostId, th.Level + 1
    FROM Tags t
    JOIN TagHierarchy th ON t.Id = th.WikiPostId
), UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation > 0
), ClosedPosts AS (
    SELECT p.Id, p.Title, COUNT(ph.Id) AS CloseCount
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    GROUP BY p.Id, p.Title
), DetailedPostStats AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount,
           COALESCE(cp.CloseCount, 0) AS CloseCount,
           COUNT(c.Id) AS CommentCount, 
           COUNT(v.Id) AS VoteCount,
           STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '<>')))
    LEFT JOIN ClosedPosts cp ON p.Id = cp.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, cp.CloseCount
)
SELECT dh.UserId, dh.DisplayName, 
       SUM(dps.Score) AS TotalScore, 
       AVG(dps.ViewCount) AS AvgViewCount,
       MAX(dh.Reputation) AS MaxReputation,
       STRING_AGG(DISTINCT dps.Title, '; ') AS PostTitles,
       SUM(CASE WHEN dh.Rank <= 10 THEN dps.CloseCount ELSE 0 END) AS TopUserCloseCount
FROM DetailedPostStats dps
JOIN UserReputation dh ON dps.Id IN (SELECT pl.RelatedPostId FROM PostLinks pl WHERE pl.PostId = dps.Id)
JOIN TagHierarchy th ON th.Id IN (SELECT unnest(string_to_array(dps.Tags, ', ')))
WHERE dps.CloseCount > 0
GROUP BY dh.UserId, dh.DisplayName
ORDER BY TotalScore DESC
LIMIT 10;
