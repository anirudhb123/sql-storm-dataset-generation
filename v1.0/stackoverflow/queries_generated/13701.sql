-- Performance benchmarking query for StackOverflow schema

-- This query retrieves a summary of posts, including the average score, total views, and number of answers grouped by post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
