-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewsPerPost,
        AVG(p.Score) AS AvgScorePerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore,
    AvgViewsPerPost,
    AvgScorePerPost
FROM 
    UserPostStats
ORDER BY 
    TotalPosts DESC
LIMIT 10;

-- Posts with the highest scores
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Questions only
ORDER BY 
    p.Score DESC
LIMIT 10;
