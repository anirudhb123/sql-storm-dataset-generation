-- Performance benchmarking query to analyze the average views for each post type
SELECT 
    pt.Name AS PostType,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(p.Id) AS TotalPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    AverageViewCount DESC;

-- Additional query to benchmark user reputation and post creation
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Query to analyze the distribution of close reasons
SELECT 
    crt.Name AS CloseReason,
    COUNT(ph.Id) AS TotalCloseActions
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes crt ON ph.Comment::int = crt.Id
WHERE 
    ph.PostHistoryTypeId = 10 -- Only considering 'Post Closed' actions
GROUP BY 
    crt.Name
ORDER BY 
    TotalCloseActions DESC;
