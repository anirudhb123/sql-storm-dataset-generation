-- Performance Benchmarking SQL Query

-- 1. Get the number of posts, their average score, and average view count per post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AvgScore,
    AVG(p.ViewCount) AS AvgViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- 2. Get users with the highest reputation and their associated badges
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- 3. Find the most active posts based on comments
SELECT 
    p.Title,
    p.CreationDate,
    COUNT(c.Id) AS CommentCount
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title, p.CreationDate
ORDER BY 
    CommentCount DESC
LIMIT 10;

-- 4. Count the number of different voting types per post
SELECT 
    p.Title,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Posts p
JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    p.Title, vt.Name
ORDER BY 
    VoteCount DESC;

-- 5. Measure the average time between post creation and first comment
SELECT 
    p.Title,
    AVG(EXTRACT(EPOCH FROM (c.CreationDate - p.CreationDate)) / 60) AS AvgMinutesToFirstComment
FROM 
    Posts p
JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Title
ORDER BY 
    AvgMinutesToFirstComment ASC;
