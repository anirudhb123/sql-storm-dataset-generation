-- Performance Benchmarking Query
SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    p.LastActivityDate,
    p.ViewCount,
    p.Score,
    COALESCE COUNT(c.Id, 0) AS CommentCount,
    COALESCE COUNT(b.Id, 0) AS BadgeCount,
    COALESCE SUM(v.VoteTypeId = 2, 0) AS UpVotes,
    COALESCE SUM(v.VoteTypeId = 3, 0) AS DownVotes,
    COALESCE AVG(ps.Score) AS AvgScoreByTags
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
    (SELECT 
         unnest(string_to_array(p.Tags, '<>')) AS tag,
         Posts.Id AS PostId,
         p.Score
     FROM 
         Posts p
     WHERE 
         p.PostTypeId = 1) ps ON p.Id = ps.PostId
WHERE 
    p.CreationDate >= '2022-01-01'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.ViewCount DESC;
