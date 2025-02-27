SET STATISTICS TIME ON;

-- Performance benchmark query to retrieve posts along with their associated user ratings, comments, and tags
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Body,
    p.CreationDate,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    STRING_AGG(DISTINCT t.TagName, ',') AS Tags
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostsTags pt ON p.Id = pt.PostId
LEFT JOIN 
    Tags t ON pt.TagId = t.Id
GROUP BY 
    p.Id, u.DisplayName, u.Reputation
ORDER BY 
    p.CreationDate DESC;

SET STATISTICS TIME OFF;
