-- Performance benchmarking query to evaluate the number of posts, users, and votes along with their average score and reputation.

SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    AVG(v.Score) AS AvgPostScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AvgUserReputation,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;
