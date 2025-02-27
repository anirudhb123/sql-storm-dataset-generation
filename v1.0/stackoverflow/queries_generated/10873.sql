-- Performance benchmarking query to retrieve user reputation and their post details
SELECT 
    u.Id AS UserId,
    u.Reputation,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.CreationDate >= NOW() - INTERVAL '1 year' -- Users created in the last year
GROUP BY 
    u.Id, p.Id
ORDER BY 
    u.Reputation DESC, p.CreationDate DESC
LIMIT 100; -- Limit to top 100 users by reputation
