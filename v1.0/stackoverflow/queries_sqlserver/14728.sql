
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.ViewCount, 
    u.DisplayName AS OwnerDisplayName, 
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    STRING_SPLIT(p.Tags, '> <') AS tag_name ON 1=1
JOIN 
    Tags t ON LTRIM(RTRIM(tag_name.value)) = t.TagName
WHERE 
    p.PostTypeId = 1  
GROUP BY 
    p.Id, p.Title, p.ViewCount, u.DisplayName
ORDER BY 
    p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
