SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    COUNT(c.Id) AS CommentCount, 
    SUM(v.VoteCount) AS TotalVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- only questions
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.CreationDate DESC
LIMIT 10;
