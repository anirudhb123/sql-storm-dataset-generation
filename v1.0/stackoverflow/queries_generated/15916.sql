SELECT 
    p.Id AS PostId, 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    p.Score, 
    p.ViewCount 
FROM 
    Posts p 
JOIN 
    Users u ON p.OwnerUserId = u.Id 
WHERE 
    p.PostTypeId = 1  -- Filter for questions
    AND p.Score > 0   -- Only include posts with a positive score
ORDER BY 
    p.CreationDate DESC
LIMIT 10;  -- Limit to the 10 most recent questions
