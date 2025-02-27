-- Performance Benchmarking SQL Query

-- Retrieve average score and view count for posts grouped by post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- Limiting to last year for more recent data
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Retrieve top users by reputation and their total number of posts
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id
ORDER BY 
    u.Reputation DESC
LIMIT 10;  -- Top 10 users

-- Analyze the distribution of votes across different post types
SELECT 
    pt.Name AS PostType,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
FROM 
    Votes v
JOIN 
    Votes vt ON v.VoteTypeId = vt.Id
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalVotes DESC;
