-- Performance Benchmarking Query for Stack Overflow Data

-- Query to find the average score and view count of questions posted by active users
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalQuestions,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
WHERE 
    p.PostTypeId = 1 -- Only questions
    AND u.Reputation > 100 -- Active users
GROUP BY 
    u.DisplayName
ORDER BY 
    AverageScore DESC, AverageViewCount DESC;

-- Query to find the distribution of post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Query to analyze comment activity on posts
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

-- Query to check the badge distribution among users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalAchieved
FROM 
    Badges b
GROUP BY 
    b.Name
ORDER BY 
    TotalAchieved DESC;
