-- Performance Benchmarking Query

-- Measuring the average time taken for different post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgTimeInSeconds
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Measuring user reputation and activity
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    COUNT(c.Id) AS TotalComments,
    COUNT(b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC;

-- Post history types performance
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS TotalHistoryRecords,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate))) AS AvgTimeSincePostCreation
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    Posts p ON ph.PostId = p.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalHistoryRecords DESC;
