
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(v.Id) AS VoteCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56') 
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
ORDER BY 
    p.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
