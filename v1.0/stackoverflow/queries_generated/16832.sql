SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.PostTypeId = 1 -- Only questions
GROUP BY 
    u.Id, p.Id
ORDER BY 
    u.Reputation DESC, p.CreationDate DESC
LIMIT 10;
