
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
CROSS APPLY 
    STRING_SPLIT(p.Tags, ', ') AS tag_array
LEFT JOIN 
    Tags t ON t.TagName = tag_array.value
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS 
FETCH NEXT 100 ROWS ONLY;
