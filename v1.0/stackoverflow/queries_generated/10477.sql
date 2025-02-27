-- Performance benchmarking query to retrieve the count of posts, average score, and average view count by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Performance benchmarking query to aggregate user reputation and count of badges acquired
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

-- Performance benchmarking query to analyze comments statistics by post
SELECT 
    p.Title,
    COUNT(c.Id) AS CommentCount,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    CommentCount DESC;

-- Performance benchmarking query to evaluate voting behavior on posts
SELECT 
    pt.Name AS PostType,
    vt.Name AS VoteType,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    VoteTypes vt ON v.VoteTypeId = vt.Id
GROUP BY 
    pt.Name, vt.Name
ORDER BY 
    VoteCount DESC;
