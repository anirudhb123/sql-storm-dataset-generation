-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MAX(ph.CreationDate) AS LastEditDate,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    STRING_SPLIT(p.Tags, ',') AS tag_split ON tag_split.value IS NOT NULL
LEFT JOIN 
    Tags t ON TRIM(tag_split.value) = t.TagName
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Filter for posts created in the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
ORDER BY 
    p.CreationDate DESC;
