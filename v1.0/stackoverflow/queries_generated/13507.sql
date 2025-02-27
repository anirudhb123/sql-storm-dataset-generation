-- Performance Benchmarking Query

-- This query retrieves information about the most recent posts along with their associated user data, tags, and vote counts.
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    STRING_TO_ARRAY(p.Tags, ', ') AS tag_array ON TRUE
LEFT JOIN 
    Tags t ON t.TagName = tag_array
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Considering posts from the last year
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limiting to the 100 most recent posts for performance
