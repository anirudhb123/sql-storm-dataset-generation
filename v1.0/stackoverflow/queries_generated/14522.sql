-- Performance Benchmarking Query to analyze post activity and user engagement
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COUNT(b.Id) AS BadgeCount
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
WHERE 
    p.CreationDate >= DATEADD(YEAR, -1, GETDATE())  -- Posts from the last year
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.Score DESC, p.ViewCount DESC
OPTION (RECOMPILE); -- Helps in performance benchmarking by generating a new execution plan
