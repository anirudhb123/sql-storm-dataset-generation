-- Performance Benchmarking Query: Analyzing Post Activity and User Engagement
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    MAX(ph.CreationDate) AS LastHistoryChange
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 month'  -- Limit to posts created in the last month
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
ORDER BY 
    p.ViewCount DESC
LIMIT 100;  -- Limit results for benchmarking output
