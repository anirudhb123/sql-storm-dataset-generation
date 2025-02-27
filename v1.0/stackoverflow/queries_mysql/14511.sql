
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    COUNT(DISTINCT u.Id) AS TotalContributors,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR
GROUP BY 
    pt.Name, p.Id, p.ViewCount, p.Score
ORDER BY 
    TotalPosts DESC;
