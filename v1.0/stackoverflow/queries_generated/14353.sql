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
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    pt.Name AS PostTypeName,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ', ') AS tags ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tags)
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for the last year
GROUP BY 
    p.Id, u.DisplayName, pt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Limit results for performance
