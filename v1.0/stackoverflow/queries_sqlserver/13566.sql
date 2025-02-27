
SELECT 
    p.Id AS PostId,
    p.Title,
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
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL '30 days'
GROUP BY 
    p.Id,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName,
    u.Reputation,
    v.VoteTypeId,
    v.CreationDate
ORDER BY 
    p.CreationDate DESC;
