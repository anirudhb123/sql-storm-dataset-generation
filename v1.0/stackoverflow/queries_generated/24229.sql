WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(p.ViewCount, 0) AS ViewCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserPostStats AS (
    SELECT 
        pm.OwnerUserId,
        COUNT(pm.PostId) AS PostCount,
        AVG(pm.Score) AS AvgScore,
        SUM(pm.CommentCount) AS TotalComments,
        SUM(pm.ViewCount) AS TotalViews
    FROM PostMetrics pm
    GROUP BY pm.OwnerUserId
),
MaxStats AS (
    SELECT 
        UPS.OwnerUserId,
        UPS.PostCount,
        UPS.AvgScore,
        UPS.TotalComments,
        UPS.TotalViews,
        RANK() OVER (ORDER BY UPS.TotalViews DESC) AS RankByViews,
        RANK() OVER (ORDER BY UPS.AvgScore DESC) AS RankByScore
    FROM UserPostStats UPS
)
SELECT 
    u.DisplayName,
    UBC.GoldBadges,
    UBC.SilverBadges,
    UBC.BronzeBadges,
    MS.PostCount,
    MS.AvgScore,
    MS.TotalComments,
    MS.TotalViews,
    CASE 
        WHEN MS.RankByViews <= 10 THEN 'Top Contributors by Views'
        ELSE NULL
    END AS ViewsCategory,
    CASE 
        WHEN MS.RankByScore <= 10 THEN 'Top Contributors by Score'
        ELSE NULL
    END AS ScoreCategory
FROM MaxStats MS
JOIN Users u ON u.Id = MS.OwnerUserId
JOIN UserBadgeCounts UBC ON UBC.UserId = u.Id
WHERE UBC.GoldBadges + UBC.SilverBadges + UBC.BronzeBadges > 0
ORDER BY MS.TotalViews DESC, MS.AvgScore DESC
OFFSET 0 ROWS
FETCH NEXT 100 ROWS ONLY;

-- Add complicating predicates based on obscure business logic
WHERE (MS.PostCount > 5 AND UBC.GoldBadges > 0) OR 
      (MS.TotalComments > 10 AND UBC.SilverBadges > 0) OR 
      (MS.TotalViews > 100 AND UBC.BronzeBadges > 0)
HAVING AVG(MS.AvgScore) > 0;

This query creates several Common Table Expressions (CTEs) to gather user badge counts, post metrics, and user statistics. It also incorporates complex ranking logic and conditional statements for categorizing users based on their activity, which is both intricate and allows for performance benchmarking.
