-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the total number of posts, average score, and average view count for each post type.
-- It also includes the number of answers for each question and average time between creation and last activity.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate)) / 3600) AS AverageTimeToActivityHours
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
