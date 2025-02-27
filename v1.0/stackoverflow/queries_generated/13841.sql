-- Performance benchmarking query for counting posts by type and their average score
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Performance benchmarking query for user reputation and their badge count
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Performance benchmarking query for post activity by user
SELECT 
    u.DisplayName AS UserName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalViews DESC;

-- Performance benchmarking query for comments per post
SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    CommentCount DESC;
