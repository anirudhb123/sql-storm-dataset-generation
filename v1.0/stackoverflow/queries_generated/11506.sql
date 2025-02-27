-- Performance Benchmarking Query for Stack Overflow Schema

-- This query retrieves the number of posts, average score, and total view count grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additionally, we can benchmark user metrics to compare user engagement
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    SUM(v.BountyAmount) AS TotalBountyEarned
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    TotalPosts DESC, u.Reputation DESC;

-- Finally, we can analyze badges received by users
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS TotalBadges,
    MAX(b.Class) AS HighestBadgeClass
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalBadges DESC, HighestBadgeClass ASC;
