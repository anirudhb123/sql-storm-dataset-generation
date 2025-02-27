-- Performance Benchmarking Query
-- This query will measure the performance of retrieving posts with their associated user data, tags, and comments
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, '<>')::int[])  -- Extracting tags from the Tags column
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filtering posts created in 2023
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limiting the number of results to the latest 100 posts for benchmarking
