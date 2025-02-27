-- Performance Benchmarking SQL Query

-- Get the total count of posts, average score, and average view count grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Get the average reputation of users who created posts, along with post count per user
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS PostCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC, AverageReputation DESC;

-- Fetch the total number of comments and average score of comments per post
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
ORDER BY 
    TotalComments DESC;

-- Analyze badge distribution by user reputation across different categories
SELECT 
    b.Class,
    COUNT(b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Class
ORDER BY 
    b.Class;
