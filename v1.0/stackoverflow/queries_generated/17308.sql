SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS Owner, 
    COUNT(c.Id) AS CommentCount, 
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes, 
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes 
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  -- Only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
