-- Performance benchmarking query for StackOverflow schema
-- This query retrieves statistics for posts and their associated data,
-- allowing for insight into post performance and user engagement.

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    p.CreationDate,
    p.AnswerCount,
    p.CommentCount,
    p.FavoriteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS TotalVotes,
    COUNT(c.Id) AS TotalComments,
    AVG(b.Reputation) AS OwnerAvgReputation, 
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= '2023-01-01'
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.ViewCount DESC, p.Score DESC;
