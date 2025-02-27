-- Performance benchmarking query for the Stack Overflow schema
-- This query retrieves user reputation statistics along with their post count, average views per post, 
-- and total upvotes and downvotes.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount,
    AVG(p.ViewCount) AS AvgViewsPerPost,
    SUM(v.UpVotes) AS TotalUpVotes,
    SUM(v.DownVotes) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    (SELECT 
        OwnerUserId, 
        SUM(UpVotes) AS UpVotes, 
        SUM(DownVotes) AS DownVotes 
     FROM 
        Users 
     GROUP BY 
        OwnerUserId) v ON u.Id = v.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;
