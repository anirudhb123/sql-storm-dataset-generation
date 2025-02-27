SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    COUNT(c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount,
    SUM(v.VoteTypeId = 3) AS DownVoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.DisplayName, p.Title
ORDER BY 
    CommentCount DESC;
