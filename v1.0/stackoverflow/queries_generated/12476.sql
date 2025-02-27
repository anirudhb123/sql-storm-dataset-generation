-- Performance Benchmarking Query

-- This query retrieves the average score and view count of questions and answers, grouping them by post type.
-- It also counts the number of comments associated with each post type for further analysis.

SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId IN (1, 2) -- 1 = Question, 2 = Answer
GROUP BY 
    pt.Name
ORDER BY 
    pt.Name;
