-- Performance benchmarking query to analyze post activity and user engagement on Stack Overflow

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    AVG(p.Score) AS AverageScore,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    COUNT(DISTINCT ph.Id) AS HistoryCount

FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId

WHERE 
    u.Reputation > 0  -- Filter to consider only users with positive reputation

GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    PostCount DESC, AverageScore DESC
LIMIT 100; -- Limit to the top 100 users by post count
