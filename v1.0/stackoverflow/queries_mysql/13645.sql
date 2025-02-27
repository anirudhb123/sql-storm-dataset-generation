
SELECT 
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    p.Score,
    p.CreationDate,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    AVG(IFNULL(TIMESTAMPDIFF(SECOND, p.CreationDate, v.CreationDate), TIMESTAMPDIFF(SECOND, p.CreationDate, NOW()))) AS AverageVoteTime
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= NOW() - INTERVAL 1 YEAR  
GROUP BY 
    p.Id, p.Title, p.ViewCount, p.Score, p.CreationDate, u.DisplayName, u.Reputation
ORDER BY 
    p.ViewCount DESC;
