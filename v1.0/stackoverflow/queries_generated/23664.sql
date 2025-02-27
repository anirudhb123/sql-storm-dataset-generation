WITH PostEngagement AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Score,
           p.ViewCount,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.UserId,
           ph.CreationDate AS HistoryDate,
           p.Title,
           r.Name AS HistoryType
    FROM PostHistory ph
    JOIN PostHistoryTypes r ON ph.PostHistoryTypeId = r.Id
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'
      AND ph.Comment IS NOT NULL
),
RecentEngagements AS (
    SELECT PostId,
           COUNT(*) AS RecentEngagementCount,
           COUNT(CASE WHEN HistoryType LIKE '%Close%' THEN 1 END) AS CloseCount,
           COUNT(CASE WHEN HistoryType LIKE '%Edit%' THEN 1 END) AS EditCount,
           COUNT(CASE WHEN HistoryType LIKE '%Rollback%' THEN 1 END) AS RollbackCount
    FROM PostHistoryDetails
    GROUP BY PostId
)
SELECT  p.Rank,
        e.PostId,
        e.Title,
        e.Score,
        e.ViewCount,
        e.TotalBounties,
        e.CommentCount,
        e.BadgeCount,
        COALESCE(r.RecentEngagementCount, 0) AS RecentEngagementCount,
        COALESCE(r.CloseCount, 0) AS CloseCount,
        COALESCE(r.EditCount, 0) AS EditCount,
        COALESCE(r.RollbackCount, 0) AS RollbackCount
FROM PostEngagement e
LEFT JOIN RecentEngagements r ON e.PostId = r.PostId
WHERE e.Rank <= 10 -- Select the top 10 posts by Score
ORDER BY e.Score DESC, e.ViewCount DESC;

-- Additional Input for obscure cases
SELECT  p.Id,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Answered'
            WHEN NOT EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) THEN 'Unanswered'
            ELSE 'Open'
        END AS PostStatus,
        CASE 
            WHEN p.TagName IS NULL THEN 'Unlabeled'
            ELSE CONCAT('Tagged with: ', p.Tags)
        END AS TagDescription
FROM Posts p
LEFT JOIN Tags t ON t.Id IN (SELECT UNNEST(string_to_array(p.Tags, '><'))::int)
WHERE p.CreationDate < '2022-01-01'
  AND p.ViewCount > 0
ORDER BY p.CreationDate DESC
LIMIT 5;

-- Handling NULL logic corner cases
SELECT u.DisplayName, 
       u.Reputation, 
       CASE 
           WHEN u.Location IS NULL THEN 'Location Unknown'
           WHEN LENGTH(u.Location) = 0 THEN 'Location Not Provided'
           ELSE u.Location 
       END AS LocationDescription,
       COALESCE(b.Name, '(No Badge)') AS LatestBadge
FROM Users u
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE u.Reputation > (SELECT AVG(Reputation) FROM Users)
  AND NOT EXISTS (SELECT 1 FROM Posts WHERE OwnerUserId = u.Id)
ORDER BY u.CreationDate DESC;
