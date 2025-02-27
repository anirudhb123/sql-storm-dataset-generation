WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) OVER (PARTITION BY u.Id) AS AverageScore,
        DENSE_RANK() OVER (ORDER BY SUM(COALESCE(p.Score, 0)) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagPopularity AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostsCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, '::int'))::int[]
    GROUP BY 
        t.TagName
),
UserBadgeInfo AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.TotalViews,
    ups.AverageScore,
    COALESCE(ubi.TotalBadges, 0) AS TotalBadges,
    COALESCE(ubi.GoldBadges, 0) AS GoldBadges,
    COALESCE(ubi.SilverBadges, 0) AS SilverBadges,
    COALESCE(ubi.BronzeBadges, 0) AS BronzeBadges,
    tp.TagName,
    tp.PostsCount,
    tp.TotalViews AS TagTotalViews,
    tp.AverageScore AS TagAverageScore
FROM 
    UserPostStats ups
LEFT JOIN 
    UserBadgeInfo ubi ON ups.UserId = ubi.UserId
LEFT JOIN 
    TagPopularity tp ON ups.UserId = tp.TagName
ORDER BY 
    ups.Rank, ups.TotalScore DESC;
