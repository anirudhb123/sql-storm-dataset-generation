-- Performance benchmarking on the Stack Overflow schema

-- Benchmarking the total number of users and their average reputation
SELECT 
    COUNT(*) AS TotalUsers,
    AVG(Reputation) AS AverageReputation
FROM 
    Users;

-- Benchmarking the number of posts and their average score
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AveragePostScore
FROM 
    Posts;

-- Benchmarking the distribution of post types
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Benchmarking user activity by counting comments made by users
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

-- Benchmarking the most popular tags based on count
SELECT 
    t.TagName,
    SUM(t.Count) AS TotalPostsWithTag
FROM 
    Tags t
GROUP BY 
    t.TagName
ORDER BY 
    TotalPostsWithTag DESC
LIMIT 10;

-- Benchmarking performance of post history
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS HistoryCount
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    HistoryCount DESC;
