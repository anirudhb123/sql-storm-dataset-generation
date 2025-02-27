-- Performance benchmarking query for Stack Overflow schema

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2020-01-01'  -- Filter for posts created after January 1, 2020
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC, p.CreationDate DESC 
LIMIT 100;  -- Limit results to top 100 posts based on score
