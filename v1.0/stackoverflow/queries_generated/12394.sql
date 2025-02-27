-- Performance Benchmarking Query

-- This query retrieves a count of posts, including the total score, views, and answer count
-- grouped by post type and sorted by total views and scores for benchmarking performance

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalViews DESC, TotalScore DESC;
