-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves user information along with their post counts, score, and reputation
-- It also aggregates the number of votes on their posts and lists their most recent activity

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    SUM(p.Score) AS TotalScore,
    SUM(v.VoteTypeId = 2) AS UpVotes,  -- Count of UpVotes (VoteTypeId = 2)
    SUM(v.VoteTypeId = 3) AS DownVotes,  -- Count of DownVotes (VoteTypeId = 3)
    MAX(p.LastActivityDate) AS LastActivity
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, TotalScore DESC
LIMIT 100;  -- Limiting to top 100 users based on post count
