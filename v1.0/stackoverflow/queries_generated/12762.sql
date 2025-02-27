-- Performance Benchmarking Query
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 1 THEN p.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN p.PostTypeId = 2 THEN p.Id END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.CreationDate) AS AvgPostAge,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        u.Reputation >= 100 -- filtering to show users with reputation of at least 100
    GROUP BY 
        u.Id
)

SELECT 
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalScore,
    TotalViews,
    AvgPostAge,
    TotalComments
FROM 
    UserPostStats
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 100; -- Limit results to top 100 users by score

