-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(v.BountyAmount) AS AvgBountyAmount,
    MAX(b.Date) AS LastBadgeDate,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.PostTypeId = 1 -- Only Questions
    AND p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Questions from the last year
GROUP BY 
    p.Id, p.Title, u.DisplayName, p.CreationDate, p.LastActivityDate, p.ViewCount
ORDER BY 
    p.ViewCount DESC;
