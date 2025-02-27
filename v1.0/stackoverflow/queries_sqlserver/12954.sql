
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
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
    (
        SELECT TRIM(BOTH ' ' FROM value) AS tag 
        FROM STRING_SPLIT(p.Tags, ',') 
    ) AS tag ON tag IS NOT NULL
LEFT JOIN 
    Tags t ON t.TagName = tag
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
