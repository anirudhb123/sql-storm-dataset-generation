-- Performance benchmarking query to analyze user activities and post engagement
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounties,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, Reputation DESC;
