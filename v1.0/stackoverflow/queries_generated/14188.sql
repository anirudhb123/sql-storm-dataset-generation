-- Performance benchmarking SQL query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filtering posts created in 2023
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.ViewCount DESC  -- Ordering by the number of views
LIMIT 100;  -- Limiting the result to 100 posts for benchmarking
