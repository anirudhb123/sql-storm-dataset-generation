WITH RecursivePostHierarchy AS (
    SELECT Id, ParentId, Title, 
           0 AS Depth,
           CAST(Title AS VARCHAR(MAX)) AS FullPath
    FROM Posts
    WHERE ParentId IS NULL
    UNION ALL
    SELECT p.Id, p.ParentId, p.Title,
           r.Depth + 1,
           CAST(r.FullPath + ' -> ' + p.Title AS VARCHAR(MAX))
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
RecentPostStats AS (
    SELECT p.Id AS PostId,
           p.Title,
           COUNT(c.Id) AS CommentCount,
           COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
           SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBountiesReceived
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
PostHistoryDetails AS (
    SELECT ph.PostId,
           ph.PostHistoryTypeId,
           ph.CreationDate,
           ph.Comment,
           p.Title,
           p.OwnerUserId
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT r.Id,
       r.Title,
       r.Depth,
       r.FullPath,
       rs.CommentCount,
       rs.TotalBounty,
       hs.PostHistoryTypeId,
       hs.CreationDate,
       hs.Comment AS HistoryComment,
       h.OwnerUserId,
       COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
FROM RecursivePostHierarchy r
LEFT JOIN RecentPostStats rs ON r.Id = rs.PostId
LEFT JOIN PostHistoryDetails hs ON r.Id = hs.PostId
LEFT JOIN Users u ON hs.OwnerUserId = u.Id
WHERE r.Depth <= 2 -- Limit depth for performance
ORDER BY r.Depth, r.Title;
