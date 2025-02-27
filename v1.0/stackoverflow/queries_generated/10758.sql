-- Performance Benchmarking Query

-- This query retrieves a summary of post activity along with user reputation
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON TRUE
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'  -- Filter for posts created in the last 30 days
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit output for performance
