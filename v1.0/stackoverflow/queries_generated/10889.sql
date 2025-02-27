-- Performance benchmarking query on Stack Overflow schema

-- This query retrieves a summary of posts, including number of answers, comments, and votes,
-- and calculates their average score grouped by PostTypeId, which can help to evaluate performance.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN p.AnswerCount ELSE 0 END) AS TotalAnswers, 
    SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
    AVG(v.Score) AS AverageScore,
    COUNT(DISTINCT v.UserId) AS TotalVoters,
    MAX(p.CreationDate) AS MostRecentPost
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Id, pt.Name
ORDER BY 
    TotalPosts DESC;
