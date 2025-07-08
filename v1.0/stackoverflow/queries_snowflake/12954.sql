
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    LATERAL FLATTEN(input => SPLIT(TRIM(BOTH ' ' FROM p.Tags), ',')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag.value
WHERE 
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
