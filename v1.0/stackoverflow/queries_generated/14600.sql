-- Performance Benchmarking Query

-- Select the total number of posts, average views, and average score per post type
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViews,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Calculate the number of active users along with their average reputation
SELECT 
    COUNT(DISTINCT u.Id) AS ActiveUsers,
    AVG(u.Reputation) AS AverageReputation
FROM 
    Users u
WHERE 
    u.LastAccessDate > NOW() - INTERVAL '30 days';

-- Benchmark the number of comments and average score per post
SELECT 
    p.Id AS PostId,
    p.Title,
    COUNT(c.Id) AS TotalComments,
    AVG(c.Score) AS AverageCommentScore
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    TotalComments DESC
LIMIT 10;

-- Assess vote distribution on posts
SELECT 
    p.Id AS PostId,
    p.Title,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title
ORDER BY 
    UpVotes DESC
LIMIT 10;

-- Analyze badges earned by users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalEarned,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    TotalEarned DESC;
