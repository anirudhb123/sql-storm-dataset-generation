-- Performance benchmarking query for StackOverflow schema

-- Aggregate statistics on post types and their associated user reputation
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AvgUserReputation,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01'  -- considering posts from this year
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- This query provides insights on different post types along with user reputation metrics
-- Useful for performance benchmarking of posts and various types of engagement on StackOverflow.
