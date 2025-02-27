-- Performance Benchmarking Query

SELECT 
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    t.TagName,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')))
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    p.Id, u.DisplayName, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
