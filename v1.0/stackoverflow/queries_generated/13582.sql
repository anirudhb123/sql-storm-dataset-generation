-- Performance benchmarking query to analyze post activity
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    (SELECT COUNT(*) FROM Posts WHERE AcceptedAnswerId = p.Id) AS AcceptedAnswerCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    u.Reputation AS UserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    p.Id, u.Reputation
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
