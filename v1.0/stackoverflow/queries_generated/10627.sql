-- Performance Benchmarking SQL Query

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    u.Id AS OwnerId,
    u.DisplayName AS OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(b.Id) AS BadgeCount,
    SUM(v.VoteTypeId = 2) AS UpVotes,
    SUM(v.VoteTypeId = 3) AS DownVotes,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    unnest(string_to_array(p.Tags, '><')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag = t.TagName
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
