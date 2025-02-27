-- Performance Benchmarking Query
-- This query retrieves all post details along with user and vote information
-- It will help assess the performance of complex joins and aggregations.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    p.AnswerCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, vt.Name
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the output to the most recent 100 posts
