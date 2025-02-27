-- Performance Benchmarking Query: Analyze the number of posts by type and their average score
SELECT 
    pt.Name AS PostType,
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

-- Analyzing user activity based on posts
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    AVG(COALESCE(p.Score, 0)) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPosts DESC;

-- Post history changes
SELECT 
    p.Title,
    p.CreationDate,
    COUNT(ph.Id) AS TotalHistoryEntries,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Title, p.CreationDate
ORDER BY 
    TotalHistoryEntries DESC;

-- Analyzing votes across posts
SELECT 
    pt.Name AS PostType,
    vt.Name AS VoteType,
    COUNT(v.Id) AS TotalVotes
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name, vt.Name
ORDER BY 
    TotalVotes DESC;
