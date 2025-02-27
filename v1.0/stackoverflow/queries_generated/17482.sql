SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Fetching only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit results to the 10 most recent questions
