-- Benchmark query to measure performance for retrieving posts with their associated users and votes
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Adjust the date range as needed
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, v.VoteTypeId
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit results for easier benchmarking
