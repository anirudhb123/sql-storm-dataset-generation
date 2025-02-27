-- Performance Benchmarking Query

-- This query will benchmark the retrieval of post details along with the associated user and vote information

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
    p.CreationDate >= '2023-01-01'  -- Filtering for posts created in 2023
ORDER BY 
    p.CreationDate DESC  -- Order by newest posts first
LIMIT 1000;  -- Limit the results to the top 1000 posts for performance testing
