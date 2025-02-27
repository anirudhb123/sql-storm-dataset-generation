
SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerDisplayName, 
    vt.Name AS VoteType
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.PostTypeId = 1
GROUP BY 
    p.Id, p.Title, p.CreationDate, u.DisplayName, vt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
