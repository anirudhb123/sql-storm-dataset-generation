-- Performance benchmarking for different aspects of the Stack Overflow schema

-- 1. Count of posts by type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts 
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- 2. Average reputation of users who have made posts
SELECT 
    AVG(u.Reputation) AS AverageReputation 
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId;

-- 3. Number of comments per post
SELECT 
    p.Id AS PostId, 
    COUNT(c.Id) AS CommentCount 
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId 
GROUP BY 
    p.Id 
ORDER BY 
    CommentCount DESC;

-- 4. Total votes per post
SELECT 
    p.Id AS PostId, 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(v.Id) AS TotalVotes 
FROM 
    Posts p 
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
GROUP BY 
    p.Id 
ORDER BY 
    TotalVotes DESC;

-- 5. Time taken for posts to receive their first vote
SELECT 
    p.Id AS PostId, 
    MIN(v.CreationDate) - p.CreationDate AS TimeToFirstVote 
FROM 
    Posts p 
JOIN 
    Votes v ON p.Id = v.PostId 
GROUP BY 
    p.Id 
ORDER BY 
    TimeToFirstVote;

-- 6. Popular tags by post count
SELECT 
    t.TagName, 
    COUNT(pt.Id) AS PostCount 
FROM 
    Tags t
LEFT JOIN 
    Posts pt ON t.Id = pt.AcceptedAnswerId
GROUP BY 
    t.TagName 
ORDER BY 
    PostCount DESC;

-- 7. Distribution of post scores
SELECT 
    Score, 
    COUNT(*) AS PostCount 
FROM 
    Posts 
GROUP BY 
    Score 
ORDER BY 
    Score;
