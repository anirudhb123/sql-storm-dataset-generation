WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount, 
           SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
           SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
           SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT p.OwnerUserId, 
           COUNT(p.Id) AS TotalPosts, 
           SUM(COALESCE(p.Score, 0)) AS TotalScore,
           SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
           MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
RankedUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, ub.BadgeCount, 
           ps.TotalPosts, ps.TotalScore, ps.TotalViews, 
           RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT ru.DisplayName, 
       ru.Reputation, 
       ru.BadgeCount, 
       ru.TotalPosts, 
       ru.TotalScore, 
       ru.TotalViews,
       COALESCE(ru.LastPostDate, 'N/A') AS LastPostDate,
       CASE 
           WHEN ru.Reputation >= 1000 THEN 'High' 
           WHEN ru.Reputation >= 500 THEN 'Medium'
           ELSE 'Low'
       END AS ReputationCategory
FROM RankedUsers ru
WHERE ru.BadgeCount > 0
ORDER BY ru.Reputation DESC 
LIMIT 10;
