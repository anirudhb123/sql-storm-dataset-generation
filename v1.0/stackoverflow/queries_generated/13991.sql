-- Performance benchmarking query for StackOverflow schema

-- Query to get the count of Posts, average score, and total view count grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Query to get the top users by reputation and their post count
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Query to analyze votes across different post types
SELECT 
    v.VoteTypeId,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN pt.Id IS NOT NULL THEN 1 ELSE 0 END) AS PostsVoted
FROM 
    Votes v
LEFT JOIN 
    Posts p ON v.PostId = p.Id
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    v.VoteTypeId
ORDER BY 
    VoteCount DESC;

-- Query to summarize badges earned by users
SELECT 
    u.DisplayName,
    COUNT(b.Id) AS BadgesCount
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.DisplayName
ORDER BY 
    BadgesCount DESC;
