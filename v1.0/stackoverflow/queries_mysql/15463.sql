
SELECT 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    v.CreationDate AS VoteDate, 
    vt.Name AS VoteType
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    v.CreationDate >= '2023-01-01'
GROUP BY 
    u.DisplayName, 
    p.Title, 
    p.CreationDate, 
    v.CreationDate, 
    vt.Name
ORDER BY 
    v.CreationDate DESC
LIMIT 100;
