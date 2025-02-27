-- Performance benchmarking query for Posts and associated Users and Votes

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
INNER JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filtering posts created in 2023
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, p.Title, p.CreationDate, p.Score, p.ViewCount, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit to the latest 100 posts
