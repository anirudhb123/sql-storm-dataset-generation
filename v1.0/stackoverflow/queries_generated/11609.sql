-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves various metrics about posts, including the number of answers, comments, and scores averaged over time.
-- It also uses join operations across several tables to analyze post types and other relationships.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.AnswerCount) AS TotalAnswers,
    SUM(p.CommentCount) AS TotalComments,
    SUM(p.FavoriteCount) AS TotalFavorites,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
    COUNT(DISTINCT c.Id) AS TotalCommentsPerPost,
    COUNT(DISTINCT b.Id) AS TotalBadgesPerUser
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
