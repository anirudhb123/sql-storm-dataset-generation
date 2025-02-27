SELECT 
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    u.DisplayName AS UserDisplayName,
    u.Reputation AS UserReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
