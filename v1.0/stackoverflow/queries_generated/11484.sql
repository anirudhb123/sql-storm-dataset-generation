-- Performance Benchmarking SQL Query for StackOverflow Schema

-- This query retrieves the number of posts, the average score of posts, and the total number of comments for each post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    COUNT(c.Id) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Performance Benchmarking SQL Query to analyze user reputation and activity

-- This query retrieves users with their total number of posts and average reputation
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score END) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Performance Benchmarking SQL Query to evaluate post edit history

-- This query counts the number of edits by each user on their posts
SELECT 
    u.DisplayName,
    COUNT(ph.Id) AS TotalEdits
FROM 
    PostHistory ph
JOIN 
    Users u ON ph.UserId = u.Id
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalEdits DESC;

-- Performance Benchmarking SQL Query analyzing badge acquisition over time

-- This query retrieves user badges with their respective classes and the count of badges each user has
SELECT 
    u.DisplayName,
    b.Class,
    COUNT(b.Id) AS BadgeCount
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    u.Id, u.DisplayName, b.Class
ORDER BY 
    u.DisplayName, b.Class;
