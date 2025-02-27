
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    p.Score,
    p.ViewCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT TRIM(t.TagName), ',') AS Tags
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
OUTER APPLY 
    STRING_SPLIT(p.Tags, ',') AS tag
LEFT JOIN 
    Tags t ON t.TagName = TRIM(tag.value)
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, CAST('2024-10-01 12:34:56' AS DATETIME))
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.LastActivityDate, p.Score, p.ViewCount
ORDER BY 
    p.LastActivityDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
