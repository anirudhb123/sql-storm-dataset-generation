-- Performance benchmarking query for the Stack Overflow schema

-- This query retrieves the number of Posts, Users, Comments, and Votes in the system
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    (SELECT COUNT(*) FROM Votes) AS TotalVotes,
    (SELECT COUNT(*) FROM Tags) AS TotalTags,
    (SELECT COUNT(*) FROM PostHistory) AS TotalPostHistoryEntries;

-- This section measures the average view count of posts, grouped by Post Type
SELECT 
    pt.Name AS PostType,
    AVG(p.ViewCount) AS AvgViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name;

-- This section retrieves the top 10 most popular posts by score
SELECT 
    p.Title,
    p.Score,
    p.CreationDate,
    u.DisplayName AS Owner
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.PostTypeId = 1  -- Only Questions
ORDER BY 
    p.Score DESC
LIMIT 10;

-- Measure the number of edits by post and average number of comments per post
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(ph.Id) AS EditCount,
    COALESCE(COUNT(c.Id), 0) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id
ORDER BY 
    EditCount DESC;

-- Summary statistics of users
SELECT 
    MIN(Reputation) AS MinReputation,
    MAX(Reputation) AS MaxReputation,
    AVG(Reputation) AS AvgReputation,
    COUNT(*) AS TotalUsers
FROM 
    Users;
