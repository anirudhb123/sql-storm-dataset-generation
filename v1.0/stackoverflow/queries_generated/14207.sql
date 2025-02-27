-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
    p.CreationDate,
    p.LastActivityDate,
    t.TagName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Posts created in the last year
GROUP BY 
    p.Id, u.DisplayName, t.TagName
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100; -- Limit results to top 100 posts
