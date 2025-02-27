-- Performance benchmarking query to analyze user activity and post engagement

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBountyAmount,
    SUM(v.VoteTypeId = 2) AS TotalUpVotes,  -- Count of UpVotes
    SUM(v.VoteTypeId = 3) AS TotalDownVotes -- Count of DownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    PostCount DESC, Reputation DESC;
