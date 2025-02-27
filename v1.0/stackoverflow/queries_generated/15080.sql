SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    COUNT(c.Id) AS CommentCount, 
    COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Assuming VoteTypeId = 2 is for upvotes
    COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- Assuming VoteTypeId = 3 is for downvotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  -- Assuming PostTypeId = 1 is for questions
GROUP BY 
    p.Id, u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
