-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    t.TagName,
    ph.CreationDate AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT unnest(string_to_array(p.Tags, '><'))::int)
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    p.Id, u.DisplayName, t.TagName, ph.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
