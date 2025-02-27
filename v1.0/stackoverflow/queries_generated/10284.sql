-- Performance Benchmarking Query: Retrieve the number of posts and associated user reputation.

SELECT 
    p.OwnerUserId,
    COUNT(p.Id) AS TotalPosts,
    u.Reputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.OwnerUserId, u.Reputation
ORDER BY 
    TotalPosts DESC
LIMIT 100;
