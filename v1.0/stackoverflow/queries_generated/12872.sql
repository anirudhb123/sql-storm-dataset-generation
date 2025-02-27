-- Performance benchmarking query for StackOverflow schema

-- Retrieve average post scores, view counts, and total comments grouped by post type
SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(c.CommentCount) AS TotalComments
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS CommentCount
     FROM 
        Comments
     GROUP BY 
        PostId) c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    pt.Name;

-- Count of posts created per user with a breakdown by their reputation level
SELECT 
    u.Reputation,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Total badges earned by users, categorized by badge class
SELECT 
    b.Class,
    COUNT(b.Id) AS BadgeCount
FROM 
    Badges b
GROUP BY 
    b.Class
ORDER BY 
    b.Class;

-- Memory utilization and performance with subquery to get recent post edits
SELECT 
    u.DisplayName AS Editor,
    COUNT(ph.Id) AS EditsCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    PostHistory ph
JOIN 
    Users u ON ph.UserId = u.Id
WHERE 
    ph.CreationDate > NOW() - INTERVAL '30 days'
GROUP BY 
    u.DisplayName
ORDER BY 
    EditsCount DESC;

-- Average time between post creation and the first comment posted
SELECT 
    AVG(EXTRACT(EPOCH FROM (c.CreationDate - p.CreationDate))) / 60 AS AvgTimeToFirstCommentMinutes
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id;
