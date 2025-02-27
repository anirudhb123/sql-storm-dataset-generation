
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    v.VoteTypeId,
    v.CreationDate AS VoteCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  
GROUP BY 
    p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, 
    u.DisplayName, u.Reputation, v.VoteTypeId, v.CreationDate
ORDER BY 
    p.CreationDate DESC  
LIMIT 1000;
