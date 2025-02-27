SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    c.CommentCount,
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
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, c.CommentCount
ORDER BY 
    p.CreationDate DESC;
