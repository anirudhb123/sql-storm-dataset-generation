-- Performance Benchmarking Query

-- Measure the number of posts and their average scores, by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Measure the activity of users based on reputation, number of posts made, and score of posts
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalPostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
HAVING 
    COUNT(p.Id) > 0
ORDER BY 
    TotalPostScore DESC;

-- Analyze vote distribution for post types
SELECT 
    pt.Name AS PostType,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    pt.Name, vt.Name
ORDER BY 
    pt.Name, VoteCount DESC;

-- Evaluate comment activity per post
SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    MAX(c.CreationDate) AS LastCommentDate
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
WHERE 
    p.CreationDate > NOW() - INTERVAL '1 year'
GROUP BY 
    p.Title
ORDER BY 
    CommentCount DESC;

-- Analyze user badge acquisition over time
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgeCount,
    MAX(b.Date) AS LastBadgeDate
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    BadgeCount DESC;
