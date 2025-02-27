-- Performance benchmarking query: Retrieve the most recent posts along with user reputation and the count of votes
SELECT 
    p.Title,
    p.CreationDate,
    u.Reputation,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter for posts created in the last 30 days
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 
    100;  -- Limit results to the most recent 100 posts
