-- Performance Benchmarking Query

-- This query retrieves metrics about posts, their scores, and associated user information
-- It calculates the average score of posts grouped by post type, along with the total number of posts and the average reputation of users who created those posts.
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore, 
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additionally, we can benchmark the total number of votes each post type has received.
SELECT 
    pt.Name AS PostType, 
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalVotes DESC;

-- A third benchmark to consider is the volume and types of comments made on posts.
SELECT 
    p.Title, 
    COUNT(c.Id) AS CommentCount, 
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10;
