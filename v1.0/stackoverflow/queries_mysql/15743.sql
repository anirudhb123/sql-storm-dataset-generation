
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS UserName, 
    t.TagName 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id 
WHERE 
    p.PostTypeId = 1 
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, t.TagName 
ORDER BY 
    p.CreationDate DESC 
LIMIT 10;
