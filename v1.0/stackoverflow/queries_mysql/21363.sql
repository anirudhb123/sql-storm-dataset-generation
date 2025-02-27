
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(COALESCE(p.CreationDate, '1970-01-01')) AS LatestPost
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CommentsStats AS (
    SELECT 
        c.UserId AS CommenterId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM Comments c
    GROUP BY c.UserId
),
UserPerformance AS (
    SELECT 
        u.Id,
        u.DisplayName,
        COALESCE(ub.BadgeCount, 0) AS TotalBadges,
        COALESCE(ps.PostCount, 0) AS TotalPosts,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.AvgScore, 0) AS AveragePostScore,
        COALESCE(cs.CommentCount, 0) AS TotalComments,
        COALESCE(cs.TotalCommentScore, 0) AS TotalCommentScore
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN CommentsStats cs ON u.Id = cs.CommenterId
),
PerformanceRanks AS (
    SELECT 
        *,
        @rank := IF(@prev_total = TotalBadges, @rank, @rank + 1) AS Rank,
        @prev_total := TotalBadges
    FROM UserPerformance, (SELECT @rank := 0, @prev_total := NULL) r
    ORDER BY TotalBadges DESC, TotalPosts DESC, TotalViews DESC
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
CombinedPerformance AS (
    SELECT 
        upr.*,
        rp.Title AS RecentPostTitle,
        rp.ViewCount AS RecentPostViews
    FROM PerformanceRanks upr
    LEFT JOIN RecentPosts rp ON upr.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
)

SELECT 
    Id,
    DisplayName,
    TotalBadges,
    TotalPosts,
    TotalViews,
    AveragePostScore,
    TotalComments,
    TotalCommentScore,
    RecentPostTitle,
    RecentPostViews
FROM CombinedPerformance
WHERE TotalBadges > 0 
OR TotalPosts > 10
OR TotalComments > 5
ORDER BY Rank
LIMIT 100 OFFSET 0;
