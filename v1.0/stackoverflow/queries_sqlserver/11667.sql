
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    u.Id AS UserId,
    u.Reputation AS UserReputation,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= CAST(DATEADD(MONTH, -1, '2024-10-01') AS DATE)
GROUP BY 
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, u.Id, u.Reputation
ORDER BY 
    p.CreationDate DESC;
