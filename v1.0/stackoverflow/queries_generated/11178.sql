-- Performance benchmarking query for the Stack Overflow schema.
-- This query fetches the count of posts by type, total votes per post, and user reputation for top users.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,   -- Assuming 2 is 'UpMod'
    SUM(v.VoteTypeId = 3) AS TotalDownvotes, -- Assuming 3 is 'DownMod'
    u.Reputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name, u.Reputation
ORDER BY 
    PostCount DESC, Reputation DESC
LIMIT 100;  -- Limit result to top 100 entries for benchmarking
