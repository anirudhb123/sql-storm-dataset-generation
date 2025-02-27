SELECT 
    p.Title, 
    p.CreationDate, 
    u.DisplayName AS OwnerName, 
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1 -- Question
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    VoteCount DESC
LIMIT 10;
