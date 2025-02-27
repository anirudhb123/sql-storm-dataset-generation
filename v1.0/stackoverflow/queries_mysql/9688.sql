
WITH RankedUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        @rank := @rank + 1 AS Rank
    FROM Users u
    CROSS JOIN (SELECT @rank := 0) r
    WHERE u.Reputation > 1000
    ORDER BY u.Reputation DESC
),

RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        @recentPostRank := IF(@currentOwnerUserId = p.OwnerUserId, @recentPostRank + 1, 1) AS RecentPostRank,
        @currentOwnerUserId := p.OwnerUserId
    FROM Posts p
    CROSS JOIN (SELECT @recentPostRank := 0, @currentOwnerUserId := NULL) r
    WHERE p.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),

UserPostStats AS (
    SELECT 
        ru.UserId,
        ru.DisplayName,
        COUNT(rp.PostId) AS PostCount,
        COALESCE(SUM(rp.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(rp.Score), 0) AS TotalScore
    FROM RankedUsers ru
    LEFT JOIN RecentPosts rp ON ru.UserId = rp.OwnerUserId
    GROUP BY ru.UserId, ru.DisplayName
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalViews,
    ups.TotalScore,
    ru.Rank
FROM UserPostStats ups
JOIN RankedUsers ru ON ups.UserId = ru.UserId
ORDER BY ups.TotalScore DESC, ups.TotalViews DESC, ups.PostCount DESC;
