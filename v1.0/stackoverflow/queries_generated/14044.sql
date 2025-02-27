-- Performance Benchmarking Query
SELECT 
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 -- Considering only Questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;
