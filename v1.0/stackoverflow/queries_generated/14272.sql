-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    bh.UserDisplayName AS LastEditor,
    bh.CreationDate AS LastEditDate
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory bh ON p.Id = bh.PostId AND bh.PostHistoryTypeId IN (4, 5) -- Edit Title or Body
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filtering posts created in the last year
GROUP BY 
    p.Id, u.DisplayName, bh.UserDisplayName
ORDER BY 
    p.LastActivityDate DESC
LIMIT 100;  -- Limit results for performance
