
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON EXISTS (SELECT 1 FROM STRING_SPLIT(p.Tags, '<>') AS tag WHERE tag.value = CAST(t.Id AS NVARCHAR(MAX)))
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
    u.DisplayName, u.Reputation, 
    t.TagName, 
    c.Text, c.CreationDate
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
