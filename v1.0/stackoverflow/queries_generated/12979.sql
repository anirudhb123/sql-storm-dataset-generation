-- Performance Benchmarking Query for StackOverflow Schema

-- Calculate average post score and total views by post type
SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AvgScore,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostType;

-- Count total badges earned by users and average reputation of users with badges
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalBadges,
    AVG(u.Reputation) AS AvgReputation
FROM 
    Badges b 
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    TotalBadges DESC;

-- Find the most active users based on the number of posts they have created
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 10;

-- Measure the number of comments per post and average score for those comments
SELECT 
    p.Title AS PostTitle,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AvgCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    CommentCount DESC
LIMIT 5;

-- Analyze closing reasons and the corresponding number of times each reason has been used
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.Id) AS CloseCount
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes cht ON ph.Comment::int = cht.Id
WHERE 
    ph.PostHistoryTypeId = 10 -- Post Closed
GROUP BY 
    cht.Name
ORDER BY 
    CloseCount DESC;
