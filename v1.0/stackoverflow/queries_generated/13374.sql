-- Performance Benchmarking SQL Query
-- This query calculates the average score of posts grouped by their types 

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS NumberOfPosts,
    AVG(p.Score) AS AverageScore,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;

-- Additionally, we can benchmark the time taken for comment creation and related attributes

SELECT 
    u.DisplayName AS User,
    COUNT(c.Id) AS NumberOfComments,
    AVG(DATEDIFF(SECOND, c.CreationDate, p.CreationDate)) AS AvgTimeToComment
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
JOIN 
    Users u ON c.UserId = u.Id
GROUP BY 
    u.DisplayName
ORDER BY 
    AvgTimeToComment ASC;

-- Lastly, reviewing the number of badges users have obtained within a specific timeframe

SELECT 
    u.DisplayName AS User,
    COUNT(b.Id) AS NumberOfBadges,
    SUM(b.Class) AS TotalBadgeClass
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    b.Date >= DATEADD(YEAR, -1, CURRENT_TIMESTAMP) -- badges obtained in the last year
GROUP BY 
    u.DisplayName
ORDER BY 
    NumberOfBadges DESC;
