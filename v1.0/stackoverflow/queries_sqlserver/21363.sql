
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
        SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
        AVG(ISNULL(p.Score, 0)) AS AvgScore,
        MAX(ISNULL(p.CreationDate, '1970-01-01')) AS LatestPost
    FROM Posts p
    GROUP BY p.OwnerUserId
),
CommentsStats AS (
    SELECT 
        c.UserId AS CommenterId,
        COUNT(c.Id) AS CommentCount,
        SUM(ISNULL(c.Score, 0)) AS TotalCommentScore
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
        RANK() OVER (ORDER BY TotalBadges DESC, TotalPosts DESC, TotalViews DESC) AS Rank
    FROM UserPerformance
),
RecentPosts AS (
    SELECT 
        p.OwnerUserId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
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
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;
