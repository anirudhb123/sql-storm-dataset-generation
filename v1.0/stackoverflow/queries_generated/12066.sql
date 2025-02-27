-- Performance Benchmarking Query

-- This query retrieves the count of various post types along with average scores and total view counts
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

-- Retrieves the top 5 users with the highest reputations
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 5;

-- Retrieves the count of comments per post type
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS TotalComments
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalComments DESC;
