-- Performance benchmarking query for the StackOverflow schema
SELECT 
    p.Title,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    Tags.TagName,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT ph.Id) AS EditCount,
    MAX(p.CreationDate) AS PostCreationDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, '::int'))::int[]
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.PostTypeId = 1 -- focusing on Questions
GROUP BY 
    p.Id, u.DisplayName, Tags.TagName
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100; -- Limit for benchmarking performance
