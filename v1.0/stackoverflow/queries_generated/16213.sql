SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Filtering for Questions only
ORDER BY 
    p.CreationDate DESC
LIMIT 10; -- Limit to the 10 most recent questions
