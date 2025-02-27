-- Performance Benchmarking Query
SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    MAX(ph.CreationDate) AS LastEditDate,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    t.TagName
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN 
    Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year'  -- Filter posts from the last year
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, t.TagName
ORDER BY 
    p.ViewCount DESC; -- Order by most viewed posts
