-- Performance benchmarking query on Stack Overflow schema

-- Fetch the count of posts, their average score, and average view count grouped by post type
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

-- Fetch the total number of users and their average reputation
SELECT 
    COUNT(u.Id) AS TotalUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u;

-- Fetch badges statistics by class type
SELECT 
    b.Class AS BadgeClass,
    COUNT(b.Id) AS TotalBadges,
    AVG(DATEDIFF(MINUTE, b.Date, GETDATE())) AS AverageAgeInMinutes
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    TotalBadges DESC;

-- Fetch post history types and the count of modifications made
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS TotalModifications
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalModifications DESC;

-- Get average comments per post
SELECT 
    p.Id AS PostId,
    AVG(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS AverageComments
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id;
