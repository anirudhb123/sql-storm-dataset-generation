-- Performance benchmarking for querying posts, users, tags, and their associated data
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    p.ViewCount,
    p.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    t.TagName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2020-01-01'  -- Filtering for posts created in 2020 and later
GROUP BY 
    p.Id, u.Id, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the result set for benchmarking purposes
