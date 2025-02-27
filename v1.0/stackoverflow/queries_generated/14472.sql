-- Benchmarking query to evaluate the performance of different operations on the StackOverflow schema

-- 1. Count total posts by type and their average scores
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- 2. Retrieve user statistics for those with the highest reputation
SELECT 
    u.DisplayName, 
    u.Reputation, 
    COUNT(DISTINCT p.Id) AS TotalPosts, 
    SUM(COALESCE(p.Score, 0)) AS TotalScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id
HAVING 
    u.Reputation > 1000
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- 3. Find the most commented posts with their comment count
SELECT 
    p.Title, 
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id
ORDER BY 
    CommentCount DESC
LIMIT 10;

-- 4. Analyze badge distribution among users
SELECT 
    b.Name AS BadgeName, 
    COUNT(b.Id) AS TotalEarned
FROM 
    Badges b
GROUP BY 
    BadgeName
ORDER BY 
    TotalEarned DESC;

-- 5. Performance of post edits in PostHistory
SELECT 
    pht.Name AS PostHistoryType, 
    COUNT(ph.Id) AS TotalRevisions
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalRevisions DESC;

-- The above queries would help in benchmarking and understanding performance across multiple dimensions of the schema.
