-- Performance benchmarking query to analyze post statistics and user engagement

SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(p.ViewCount) AS AverageViews,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments,
    COUNT(v.Id) AS TotalVotes,
    AVG(b.Reputation) AS AverageUserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Consider posts from the last year for benchmarking
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;
