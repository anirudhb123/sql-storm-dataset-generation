WITH UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadgeCount,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadgeCount,
        SUM(CASE WHEN b.TagBased = 1 THEN 1 ELSE 0 END) AS TagBasedBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), 
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS AnswerCount
    FROM Posts p
    GROUP BY p.OwnerUserId
), 
UserPerformance AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        uc.GoldBadgeCount,
        uc.SilverBadgeCount,
        uc.BronzeBadgeCount,
        uc.TagBasedBadges,
        ps.PostCount,
        ps.TotalViews,
        ps.AvgScore,
        ps.QuestionCount,
        ps.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY uc.TagBasedBadges ORDER BY ps.TotalViews DESC) AS RankByViews
    FROM Users u
    LEFT JOIN UserBadgeCount uc ON u.Id = uc.UserId
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    TagBasedBadges,
    PostCount,
    TotalViews,
    AvgScore,
    QuestionCount,
    AnswerCount,
    RankByViews,
    CONCAT('User ', DisplayName, ' has ', GoldBadgeCount, ' Gold, ', SilverBadgeCount, ' Silver, and ', BronzeBadgeCount, ' Bronze badges. Total views: ', TotalViews, '. Average score: ', AvgScore) AS Summary,
    CASE 
        WHEN AvgScore IS NULL THEN 'No posts available.'
        WHEN AvgScore > 5 THEN 'Highly regarded user.'
        ELSE 'User needs improvement.'
    END AS PerformanceIndicator
FROM UserPerformance
WHERE PostCount IS NOT NULL 
  AND (GoldBadgeCount + SilverBadgeCount + BronzeBadgeCount) > 0
ORDER BY RankByViews, TotalViews DESC
LIMIT 20;
