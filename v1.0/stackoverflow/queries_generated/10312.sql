-- Performance benchmarking query to analyze user activity, post statistics, and the relationship between posts and users.
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.VoteTypeId = 2) AS UpVoteCount, -- UpVotes
    SUM(v.VoteTypeId = 3) AS DownVoteCount, -- DownVotes
    AVG(p.Score) AS AvgPostScore,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    u.Reputation > 0 -- considering only users with positive reputation
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, u.Reputation DESC;
