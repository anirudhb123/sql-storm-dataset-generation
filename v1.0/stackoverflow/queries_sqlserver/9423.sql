
WITH UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount, 
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT p.OwnerUserId, COUNT(p.Id) AS PostCount, SUM(p.ViewCount) AS TotalViews, 
           AVG(p.Score) AS AverageScore, COUNT(DISTINCT p.Tags) AS UniqueTagCount
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY
    GROUP BY p.OwnerUserId
),
CombinedStats AS (
    SELECT u.Id AS UserId, u.DisplayName, 
           ISNULL(ub.BadgeCount, 0) AS BadgeCount, 
           ISNULL(ub.GoldCount, 0) AS GoldCount, 
           ISNULL(ub.SilverCount, 0) AS SilverCount, 
           ISNULL(ub.BronzeCount, 0) AS BronzeCount,
           ISNULL(ps.PostCount, 0) AS PostCount, 
           ISNULL(ps.TotalViews, 0) AS TotalViews, 
           ISNULL(ps.AverageScore, 0) AS AverageScore, 
           ISNULL(ps.UniqueTagCount, 0) AS UniqueTagCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT UserId, DisplayName, BadgeCount, GoldCount, SilverCount, BronzeCount,
       PostCount, TotalViews, AverageScore, UniqueTagCount
FROM CombinedStats
WHERE BadgeCount > 0
ORDER BY TotalViews DESC, PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
