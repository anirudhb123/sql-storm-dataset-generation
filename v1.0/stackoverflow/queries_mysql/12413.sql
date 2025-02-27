
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
    Tags t ON FIND_IN_SET(t.Id, REPLACE(p.Tags, '<>', ',')) > 0
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
LIMIT 100;
