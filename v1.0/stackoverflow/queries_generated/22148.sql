WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '90 days'
      AND p.OwnerUserId IS NOT NULL
),
ActiveUsers AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           u.Reputation,
           COUNT(DISTINCT p.Id) AS NumPosts,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT p.Id) > 5
),
PostChanges AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.UserId,
           CASE 
               WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closure status changed'
               WHEN ph.PostHistoryTypeId IN (12, 13) THEN 'Deletion status changed'
               ELSE 'Other changes'
           END AS ChangeType
    FROM PostHistory ph
    WHERE ph.CreationDate >= CURRENT_DATE - INTERVAL '180 days'
),
ClosedPosts AS (
    SELECT p.Id,
           p.Title,
           p.Score,
           COALESCE(MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END), 
                    MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END)) AS LastClosedDate
    FROM Posts p
    JOIN PostChanges ph ON p.Id = ph.PostId
    WHERE p.ClosedDate IS NOT NULL
    GROUP BY p.Id, p.Title, p.Score
)
SELECT u.DisplayName,
       u.Reputation,
       COUNT(DISTINCT p.PostId) AS TotalPosts,
       SUM(CASE WHEN p.LastClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostsCount,
       AVG(COALESCE(NULLIF(p.Score, 0), NULL)) AS AvgScore,
       STRING_AGG(DISTINCT CASE WHEN tags.Id IS NOT NULL THEN tags.TagName END, ', ') AS AssociatedTags
FROM ActiveUsers u
LEFT JOIN RankedPosts p ON u.NumPosts > 0
LEFT JOIN PostsTags tags ON p.PostId = tags.PostId
LEFT JOIN Tags t ON tags.TagId = t.Id
GROUP BY u.UserId, u.DisplayName, u.Reputation
HAVING COUNT(DISTINCT p.PostId) <= (SELECT AVG(NumPosts) FROM ActiveUsers)
   AND SUM(CASE WHEN p.LastClosedDate IS NOT NULL THEN 1 ELSE 0 END) > 2
ORDER BY AvgScore DESC, ClosedPostsCount DESC
LIMIT 10;

-- Note: The PostsTags table is assumed for association between posts and tags.
This SQL query incorporates multiple advanced concepts such as CTEs (Common Table Expressions), correlated subqueries, conditional aggregation, window functions, and string aggregation. It further examines user engagement, post closure history, and associates posts with their tags while applying complex filtering and ranking mechanisms.
