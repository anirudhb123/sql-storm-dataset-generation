-- Performance Benchmarking Query: Retrieve the latest posts along with user information and tag details

SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate AS PostCreationDate,
    u.Id AS UserId,
    u.DisplayName AS UserDisplayName,
    u.Reputation,
    t.TagName,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '30 days'  -- Filter for posts created in the last 30 days
GROUP BY 
    p.Id, u.Id, t.TagName
ORDER BY 
    p.CreationDate DESC
LIMIT 100;  -- Limit the result to the 100 most recent posts
