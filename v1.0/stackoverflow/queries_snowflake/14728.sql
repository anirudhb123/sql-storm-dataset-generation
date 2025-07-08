
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    LISTAGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    LATERAL FLATTEN(INPUT => SPLIT(p.Tags, '> <')) AS tag_name ON TRUE
JOIN 
    Tags t ON TRIM(tag_name.VALUE) = t.TagName
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, p.ViewCount, u.DisplayName
ORDER BY 
    p.ViewCount DESC
LIMIT 10;
