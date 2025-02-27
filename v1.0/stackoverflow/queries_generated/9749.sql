WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        MAX(u.Reputation) AS MaxReputation
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS PostCount, 
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        p.PostCount,
        p.TotalScore,
        p.TotalViews,
        b.BadgeCount,
        u.CreationDate,
        u.LastAccessDate,
        DATEDIFF('day', u.CreationDate, u.LastAccessDate) AS ActiveDays
    FROM Users u
    LEFT JOIN PostStatistics p ON u.Id = p.OwnerUserId
    LEFT JOIN UserBadgeCounts b ON u.Id = b.UserId
    WHERE u.Reputation > 1000 AND b.BadgeCount > 0
)
SELECT 
    up.UserId, 
    up.DisplayName, 
    up.PostCount, 
    up.TotalScore, 
    up.TotalViews, 
    up.BadgeCount, 
    up.ActiveDays,
    ROW_NUMBER() OVER(ORDER BY up.TotalScore DESC) AS Rank
FROM UserPerformance up
ORDER BY up.TotalScore DESC, up.PostCount DESC
LIMIT 100;
