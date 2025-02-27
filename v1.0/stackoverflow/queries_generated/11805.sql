-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
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
LEFT JOIN 
    Tags t ON p.Tags @> ARRAY[t.TagName]::varchar[]  -- Assuming Tags is stored in a format that can be directly compared; adapt if necessary
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
