
SELECT 
    p.Title,
    p.CreationDate,
    u.Reputation,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY  
GROUP BY 
    p.Title, p.CreationDate, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 
    100;
