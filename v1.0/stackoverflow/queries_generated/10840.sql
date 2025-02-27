-- Performance Benchmarking Query

-- This query retrieves the total number of posts, average score per post, and the total number of comments grouped by post type.
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

-- Additionally, retrieve the top users based on reputation and the total number of posts created by each user.
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Lastly, count the total number of badges earned by each user.
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
ORDER BY 
    TotalBadges DESC
LIMIT 10;
