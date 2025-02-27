-- Performance Benchmarking Query

-- This query retrieves the count of posts, average score, and total views grouped by post type.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additional benchmarking on users (number of posts and reputation)
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS TotalPosts,
    SUM(u.Reputation) AS TotalReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- Benchmarking the number of comments made on posts
SELECT 
    p.Title AS PostTitle,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    TotalComments DESC;

-- Benchmarking votes by type
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    TotalVotes DESC;
