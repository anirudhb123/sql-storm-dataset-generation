-- Performance benchmarking for retrieving posts with associated users and tags

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')  -- Assuming Tags is stored as <tag1><tag2> format
WHERE 
    p.CreationDate >= '2023-01-01'  -- Filter for posts created this year
ORDER BY 
    p.Score DESC, 
    p.ViewCount DESC
LIMIT 100;  -- Limit results to top 100 posts
