
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
    COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
    SUM(ISNULL(p.Score, 0)) AS TotalScore,
    SUM(ISNULL(p.ViewCount, 0)) AS TotalViews,
    AVG(ISNULL(p.Score, 0)) AS AvgScorePerPost,
    AVG(ISNULL(p.ViewCount, 0)) AS AvgViewsPerPost
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;
