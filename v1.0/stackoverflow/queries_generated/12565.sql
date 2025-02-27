-- Performance benchmarking query for the Stack Overflow schema

-- 1. Get the total number of posts and their average score grouped by post type
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

-- 2. Calculate the average number of votes per post and total views for users with over 1000 reputation
SELECT 
    u.DisplayName AS UserName,
    COUNT(v.Id) AS TotalVotes,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore
FROM 
    Users u
JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON v.PostId = p.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalVotes DESC, TotalViews DESC;

-- 3. Fetch details for posts that received the most comments in the last month
SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    p.CreationDate
FROM 
    Posts p
JOIN 
    Comments c ON c.PostId = p.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 month'
GROUP BY 
    p.Title, p.CreationDate
ORDER BY 
    CommentCount DESC
LIMIT 10;

-- 4. Analyze badge distribution among users based on reputation
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS BadgeCount,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    BadgeCount DESC;

-- 5. Retrieve post history events for the most recent edits
SELECT 
    p.Title,
    ph.CreationDate,
    pht.Name AS HistoryType,
    ph.Comment
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    ph.CreationDate DESC
LIMIT 10;
