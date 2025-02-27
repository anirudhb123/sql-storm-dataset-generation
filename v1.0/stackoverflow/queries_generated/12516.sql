-- Performance Benchmarking Query for StackOverflow Schema

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    (SELECT COUNT(b.Id) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BadgeCount,
    u.Reputation AS OwnerReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
WHERE 
    p.PostTypeId = 1 -- Only Questions
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100; -- Limit to top 100 posts for benchmarking
