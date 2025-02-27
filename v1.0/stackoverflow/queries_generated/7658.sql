WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.CommentCount) AS TotalComments
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY UserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COALESCE(a.PostCount, 0) AS PostCount,
        COALESCE(a.TotalScore, 0) AS TotalScore,
        COALESCE(a.TotalViews, 0) AS TotalViews,
        COALESCE(a.TotalComments, 0) AS TotalComments,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        COALESCE(b.GoldCount, 0) AS GoldCount,
        COALESCE(b.SilverCount, 0) AS SilverCount,
        COALESCE(b.BronzeCount, 0) AS BronzeCount
    FROM Users u
    LEFT JOIN ActiveUsers a ON u.Id = a.UserId
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    ORDER BY TotalScore DESC, PostCount DESC
)
SELECT 
    u.UserId, 
    u.DisplayName, 
    u.PostCount, 
    u.TotalScore, 
    u.TotalViews, 
    u.TotalComments,
    u.BadgeCount,
    u.GoldCount,
    u.SilverCount,
    u.BronzeCount
FROM UserStats u
WHERE u.BadgeCount > 0
LIMIT 10;
