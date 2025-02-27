-- Performance benchmarking query for posts with their associated user details, tags, and vote counts
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ',') AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_array.value
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 month' -- Filter to last month
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;
