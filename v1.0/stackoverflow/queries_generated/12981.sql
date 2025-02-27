-- Performance Benchmarking Query

-- This query retrieves the count of posts, average view count, and total score, grouped by post type.
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(p.Score) AS TotalScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additional benchmark: retrieves total number of users and average reputation
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- Additional benchmark: retrieves total number of comments per post
SELECT 
    p.Id AS PostId,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id;

-- Additional benchmark: retrieves the number of votes by type
SELECT 
    vt.Name AS VoteTypeName,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
