-- Performance benchmarking query on the Stack Overflow schema

-- This query will benchmark the time taken to retrieve users with their associated posts, comments and badges.
-- It will measure the impact of joining multiple tables and filtering based on various criteria.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(u.UpVotes) AS TotalUpVotes,
    SUM(u.DownVotes) AS TotalDownVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.Reputation > 1000  -- Filtering for users with reputation greater than 1000
    AND u.CreationDate < '2021-01-01'  -- Only consider users created before a certain date
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    TotalUpVotes DESC  -- Ordering by the total number of upvotes received
LIMIT 100;  -- Limiting to top 100 users for performance
