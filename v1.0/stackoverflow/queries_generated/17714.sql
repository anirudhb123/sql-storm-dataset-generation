SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    COUNT(c.Id) AS CommentCount, 
    SUM(v.VoteTypeId = 2) AS UpVotes, 
    SUM(v.VoteTypeId = 3) AS DownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Selecting only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
