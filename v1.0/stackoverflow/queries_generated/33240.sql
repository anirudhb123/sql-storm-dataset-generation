WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, LastAccessDate, 
           CAST(DisplayName AS VARCHAR(50)) AS HierarchyPath
    FROM Users
    WHERE Id = (SELECT MIN(Id) FROM Users)  -- Starting with the user with the lowest Id

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.LastAccessDate,
           CONCAT(uh.HierarchyPath, ' > ', u.DisplayName)
    FROM Users u
    JOIN UserHierarchy uh ON u.Id != uh.Id AND u.Reputation > uh.Reputation
)
, PostStats AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.ViewCount, 
           COALESCE(pb.BadgeCount, 0) AS BadgeCount,
           p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) pb ON p.OwnerUserId = pb.UserId
)
, ClosedPosts AS (
    SELECT h.PostId, 
           h.CreationDate AS ClosingDate,
           h.UserId AS CloserId,
           h.Comment AS CloseReason
    FROM PostHistory h
    JOIN PostHistoryTypes ht ON h.PostHistoryTypeId = ht.Id
    WHERE ht.Name = 'Post Closed'
)
SELECT uh.DisplayName AS UserName,
       uh.Reputation,
       ps.Title AS PostTitle,
       ps.ViewCount,
       ps.BadgeCount,
       ps.Score,
       cp.ClosingDate,
       cp.CloseReason
FROM UserHierarchy uh
JOIN PostStats ps ON uh.Id = ps.PostId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
WHERE uh.Reputation > 1000  -- Filtering users with high reputation
ORDER BY uh.Reputation DESC, ps.ViewCount DESC
LIMIT 50;  -- Limiting the results for performance benchmarking
