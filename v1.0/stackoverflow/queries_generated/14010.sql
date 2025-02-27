-- Performance Benchmarking Query
SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.ViewCount AS PostViews,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    AVG(DATEDIFF(second, p.CreationDate, COALESCE(c.CreationDate, CURRENT_TIMESTAMP))) AS AvgTimeToFirstComment
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= DATEADD(year, -1, CURRENT_TIMESTAMP) -- Posts created in the last year
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.ViewCount
ORDER BY 
    p.ViewCount DESC; -- Order by post views for performance comparison
