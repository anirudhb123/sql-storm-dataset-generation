WITH RecursivePostHierarchy AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.ParentId, 
           p.CreationDate,
           p.ViewCount,
           0 AS Level
    FROM Posts p
    WHERE p.ParentId IS NULL
    
    UNION ALL
    
    SELECT p2.Id AS PostId, 
           p2.Title, 
           p2.ParentId, 
           p2.CreationDate,
           p2.ViewCount,
           Level + 1
    FROM Posts p2
    INNER JOIN RecursivePostHierarchy r ON p2.ParentId = r.PostId
),
UserStats AS (
    SELECT u.Id AS UserId,
           u.DisplayName,
           COUNT(DISTINCT p.Id) AS TotalPosts,
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
           SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
           AVG(p.ViewCount) AS AvgViewCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
PostHistorySummary AS (
    SELECT ph.PostId,
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ClosureEvents,
           COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 END) AS EditEvents
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT DISTINCT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.PositivePosts,
    u.NegativePosts,
    u.AvgViewCount,
    p.PostId,
    p.Title,
    ph.ClosureEvents,
    ph.EditEvents,
    rh.Level
FROM UserStats u
INNER JOIN Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN PostHistorySummary ph ON p.Id = ph.PostId
LEFT JOIN RecursivePostHierarchy rh ON p.Id = rh.PostId
WHERE u.TotalPosts > 10
  AND (u.AvgViewCount IS NULL OR u.AvgViewCount > 100)
  AND (ph.EditEvents > 5 OR ph.ClosureEvents = 0)
ORDER BY u.TotalPosts DESC, u.PositivePosts DESC;
