
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL FLATTEN(input => SPLIT(p.Tags, ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag.value)
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
ORDER BY 
    p.LastActivityDate DESC
LIMIT 100;
