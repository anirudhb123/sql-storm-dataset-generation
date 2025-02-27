-- Performance Benchmarking SQL Query

-- Analyzing the number of posts, average scores, and average views per user
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    COALESCE(AVG(p.Score), 0) AS AverageScore,
    COALESCE(AVG(p.ViewCount), 0) AS AverageViewCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- Analyzing the distribution of post types (Questions, Answers, etc.)
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Analyzing the most common close reasons and their frequency
SELECT 
    c.Name AS CloseReason,
    COUNT(ph.Id) AS TotalCloseActions
FROM 
    CloseReasonTypes c
JOIN 
    PostHistory ph ON ph.Comment::int = c.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 11) -- Filtering for closed and reopened posts
GROUP BY 
    c.Name
ORDER BY 
    TotalCloseActions DESC;

-- Analyzing the average time taken to close posts
SELECT 
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate)) / 3600) AS AverageHoursToClose
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId = 10; -- Considering only closed posts

-- Analyzing user reputation vs. number of badges earned
SELECT 
    u.Reputation AS UserReputation,
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Reputation
ORDER BY 
    UserReputation DESC;
