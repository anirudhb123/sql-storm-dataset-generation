-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves counts of different post types, total votes, and user details
-- to benchmark performance on aggregating data across multiple tables.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,
    SUM(v.VoteTypeId = 3) AS TotalDownvotes,
    AVG(u.Reputation) AS AvgUserReputation,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2022-01-01' -- Filter for posts created in 2022 and later
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
