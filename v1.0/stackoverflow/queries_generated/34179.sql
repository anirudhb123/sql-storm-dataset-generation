WITH RecursivePostCTE AS (
    SELECT p.Id, p.ParentId, p.Title, p.CreationDate, 
           p.Score, 1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Select only questions

    UNION ALL

    SELECT p2.Id, p2.ParentId, p2.Title, p2.CreationDate, 
           p2.Score, rp.Level + 1
    FROM Posts p2
    INNER JOIN RecursivePostCTE rp ON p2.ParentId = rp.Id
),
UserReputation AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS TotalPosts, 
           SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
           AVG(COALESCE(p.Score,0)) AS AvgScore
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY p.OwnerUserId
),
BadgesSummary AS (
    SELECT b.UserId, COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
ClosingPosts AS (
    SELECT ph.PostId, COUNT(*) AS CloseCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY ph.PostId
)

SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    COALESCE(ps.TotalPosts, 0) AS TotalPostsByUser,
    COALESCE(ps.TotalViews, 0) AS TotalViewsByUser,
    COALESCE(ps.AvgScore, 0) AS AvgScoreByUser,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(cp.CloseCount, 0) AS CloseCount,
    rp.Level AS PostLevel
FROM Posts p
INNER JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN PostStats ps ON p.OwnerUserId = ps.OwnerUserId
LEFT JOIN BadgesSummary bs ON p.OwnerUserId = bs.UserId
LEFT JOIN ClosingPosts cp ON p.Id = cp.PostId
LEFT JOIN RecursivePostCTE rp ON p.Id = rp.Id
WHERE p.PostTypeId = 1 -- Questions only
AND p.CreationDate >= CURRENT_DATE - INTERVAL '90 days' -- Filter for recent questions
ORDER BY p.CreationDate DESC;

