-- Benchmarking query to analyze user engagement and post interactions
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON c.UserId = u.Id
LEFT JOIN 
    Votes v ON v.UserId = u.Id
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalUpvotes DESC;
