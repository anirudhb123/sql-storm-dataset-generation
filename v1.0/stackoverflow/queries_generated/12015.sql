-- Performance Benchmarking Query

-- Measure the count of posts by type, average score, and total views
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Measure user activity by reputation level
SELECT 
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(COALESCE(c.Score, 0)) AS TotalCommentScore,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Reputation
ORDER BY 
    Reputation DESC;

-- Analyze post history types to find the most common edits
SELECT 
    pht.Name AS PostHistoryTypeName,
    COUNT(ph.Id) AS EditCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    EditCount DESC;
