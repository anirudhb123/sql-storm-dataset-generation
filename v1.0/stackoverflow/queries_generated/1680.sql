WITH RecentUsers AS (
    SELECT Id, DisplayName, Reputation, CreationDate,
           ROW_NUMBER() OVER (ORDER BY CreationDate DESC) AS rn
    FROM Users
    WHERE LastAccessDate > NOW() - INTERVAL '1 year'
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(*) AS TotalPosts, 
           SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
           SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
           AVG(p.ViewCount) AS AvgViews,
           STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN Tags t ON t.WikiPostId = p.Id
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
Combined AS (
    SELECT u.Id AS UserId, u.DisplayName, COALESCE(ps.TotalPosts, 0) AS TotalPosts,
           COALESCE(ps.PositivePosts, 0) AS PositivePosts, COALESCE(ps.NegativePosts, 0) AS NegativePosts, 
           COALESCE(ps.AvgViews, 0) AS AvgViews, COALESCE(ub.BadgeCount, 0) AS BadgeCount
    FROM RecentUsers u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 100 
)
SELECT c.UserId, c.DisplayName, c.TotalPosts, c.PositivePosts, c.NegativePosts, 
       c.AvgViews, c.BadgeCount
FROM Combined c
WHERE c.BadgeCount > 1
ORDER BY c.TotalPosts DESC, c.BadgeCount DESC
LIMIT 10
UNION ALL
SELECT -1 AS UserId, 'Aggregate' AS DisplayName, 
       COUNT(*) AS TotalPosts, 
       SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
       SUM(CASE WHEN Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
       AVG(ViewCount) AS AvgViews, 
       0 AS BadgeCount
FROM Posts
WHERE CreationDate > NOW() - INTERVAL '1 year';
