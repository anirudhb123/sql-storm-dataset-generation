-- Performance benchmarking for selecting most recent posts along with user and tag information
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    t.TagName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostTags pt ON p.Id = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'  -- Filter to last 30 days
GROUP BY 
    p.Id, u.DisplayName, u.Reputation, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit to 100 most recent posts
