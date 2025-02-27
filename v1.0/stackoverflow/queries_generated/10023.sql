-- Performance benchmarking query to analyze user activity and post statistics
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
    COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(COALESCE(DATEDIFF(second, p.CreationDate, p.LastActivityDate), 0)) AS AvgPostActivityDuration,
    SUM(b.Class = 1) AS GoldBadges,
    SUM(b.Class = 2) AS SilverBadges,
    SUM(b.Class = 3) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
