-- Performance benchmarking query to analyze post statistics and user engagement
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS QuestionsWithScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViews,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    COUNT(DISTINCT u.Id) AS UniqueUsers,
    SUM(c.Id IS NOT NULL) AS TotalComments,
    SUM(b.Id IS NOT NULL) AS TotalBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Filter for the last year
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
