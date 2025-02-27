-- Performance benchmarking for Users, Posts, and Votes
SELECT 
    u.Id AS UserId,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    AVG(p.Score) AS AveragePostScore,
    AVG(DATEDIFF(NOW(), p.CreationDate)) AS AvgPostAgeInDays
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id, u.Reputation
ORDER BY 
    TotalPosts DESC, Reputation DESC;
