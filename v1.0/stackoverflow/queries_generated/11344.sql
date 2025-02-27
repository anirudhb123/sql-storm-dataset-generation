-- Performance benchmarking query for the Stack Overflow schema

-- Measuring the number of posts by type and their average score
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

-- Measuring user activity by reputation
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Benchmarking comment activity on posts
SELECT 
    p.Title,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
HAVING 
    COUNT(c.Id) > 0
ORDER BY 
    TotalComments DESC;

-- Analyzing badges earned by users
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS TotalBadges,
    SUM(b.Class) AS TotalBadgeClass
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalBadges DESC;
