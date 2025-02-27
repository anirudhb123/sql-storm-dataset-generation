-- Performance benchmarking query for various operations in StackOverflow schema

-- 1. Count the number of posts by type
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

-- 2. Retrieve latest posts and their authors
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    u.DisplayName AS Author
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
ORDER BY 
    p.CreationDate DESC
LIMIT 10;

-- 3. Aggregate views per user
SELECT 
    u.DisplayName,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalViews DESC
LIMIT 10;

-- 4. Get post scores over time (last 30 days)
SELECT 
    DATE(p.CreationDate) AS PostDate,
    SUM(p.Score) AS TotalScore
FROM 
    Posts p
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'
GROUP BY 
    DATE(p.CreationDate)
ORDER BY 
    PostDate;

-- 5. Count of votes per vote type
SELECT 
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    vt.Name
ORDER BY 
    VoteCount DESC;

-- 6. Count of comments per post
SELECT 
    p.Id,
    p.Title,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    CommentCount DESC
LIMIT 10;

-- 7. Recent badge awards to users
SELECT 
    u.DisplayName,
    b.Name AS BadgeName,
    b.Date AS AwardDate
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
ORDER BY 
    b.Date DESC
LIMIT 10;
