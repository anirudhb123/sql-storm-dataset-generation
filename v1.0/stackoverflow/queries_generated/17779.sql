SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author,
    COUNT(c.Id) AS CommentCount,
    COALESCE(SUM(vote.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE(SUM(vote.VoteTypeId = 3), 0) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes vote ON p.Id = vote.PostId
WHERE 
    p.PostTypeId = 1 -- Only question posts
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
