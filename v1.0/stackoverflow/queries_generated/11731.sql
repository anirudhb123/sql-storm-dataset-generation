-- Performance Benchmarking Query

-- Calculate average, min, and max view count for different post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    MIN(p.ViewCount) AS MinViewCount,
    MAX(p.ViewCount) AS MaxViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Calculate the number of posts closed and reopened, along with their average score
SELECT 
    PHT.Name AS PostHistoryType,
    COUNT(ph.Id) AS TotalOccurrences,
    AVG(p.Score) AS AverageScore
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    PHT.Id IN (10, 11)  -- Close and Reopen actions
GROUP BY 
    PHT.Name;

-- User performance based on reputation and number of posts created
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS NumberOfPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Get the most active users based on comment count
SELECT 
    u.DisplayName,
    COUNT(c.Id) AS CommentCount
FROM 
    Users u
LEFT JOIN 
    Comments c ON u.Id = c.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    CommentCount DESC
LIMIT 10;
