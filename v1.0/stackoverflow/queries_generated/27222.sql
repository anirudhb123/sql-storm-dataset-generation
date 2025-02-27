WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(b.Class = 1) AS GoldBadges, 
        SUM(b.Class = 2) AS SilverBadges, 
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Tags,
        COUNT(*) AS TagCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.Score) AS AverageScore,
        ARRAY_AGG(DISTINCT b.Name) AS PostBadges
    FROM 
        Posts p
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY 
        p.Tags
)
SELECT 
    ua.DisplayName,
    ua.Reputation,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.TotalComments,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges,
    ps.Tags,
    ps.TagCount,
    ps.TotalViews,
    ps.AverageScore,
    ps.PostBadges
FROM 
    UserActivity ua
JOIN 
    PostStatistics ps ON ps.TagCount > 1
ORDER BY 
    ua.Reputation DESC, ua.TotalPosts DESC;

