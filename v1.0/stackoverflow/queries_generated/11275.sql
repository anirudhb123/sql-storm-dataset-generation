-- Performance benchmarking query to analyze the number of posts and their associated comments along with user reputation
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    p.Score AS PostScore,
    COUNT(c.Id) AS CommentCount,
    u.Reputation AS UserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    PostScore DESC, CommentCount DESC;
