-- Performance Benchmarking Query

-- This query will return the total number of posts, the number of users, 
-- and the average score of posts categorized by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    AVG(p.Score) AS AverageScore
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

-- Also, let's check the number of comments and average view counts per post type 
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS TotalComments,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalComments DESC;

-- Finally, let's look at the badges awarded to users to analyze user engagement.
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalBadges,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    TotalBadges DESC;
