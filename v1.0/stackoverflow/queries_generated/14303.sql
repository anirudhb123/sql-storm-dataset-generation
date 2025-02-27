-- Performance benchmarking query to retrieve posts with user details, tags, and votes
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    ARRAY_AGG(t.TagName) AS Tags,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    p.CreationDate >= '2023-01-01' -- You can modify the date filter for your benchmarking
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100; -- Adjust the limit as needed for benchmarking
