
SELECT 
    p.Id as PostId,
    p.Title,
    u.DisplayName as OwnerName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON p.Tags LIKE '%' + t.TagName + '%'
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.ViewCount, p.Score, t.TagName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
