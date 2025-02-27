SELECT 
    p.Id AS PostId, 
    p.Title AS PostTitle, 
    p.CreationDate AS PostCreationDate, 
    u.DisplayName AS OwnerDisplayName, 
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
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
