-- Performance benchmarking query to retrieve user activity along with their posts and votes
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
    SUM(CASE WHEN v.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVoteCount,
    SUM(CASE WHEN p.CreatedDate >= NOW() - INTERVAL '1 month' THEN 1 ELSE 0 END) AS RecentPostsCount,
    COUNT(DISTINCT b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 0
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, VoteCount DESC
LIMIT 100;
