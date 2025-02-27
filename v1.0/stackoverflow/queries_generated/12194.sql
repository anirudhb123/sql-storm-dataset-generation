-- Performance Benchmarking Query

-- This query will benchmark performance by aggregating post data specific actions 
-- and group by post types to evaluate performance metrics like average score, 
-- average views, and total answers for each post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews,
    SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN p.PostTypeId = 1 THEN CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END ELSE 0 END) AS AcceptedAnswers,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
