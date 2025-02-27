-- Performance Benchmarking Query

-- Calculate the total number of posts and their average view count, grouped by post type
SELECT 
    pt.Name AS PostType, 
    COUNT(p.Id) AS TotalPosts, 
    AVG(p.ViewCount) AS AverageViewCount, 
    SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS TotalScoredPosts
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Retrieve the top 10 users by reputation and their total number of posts
SELECT 
    u.DisplayName AS UserName, 
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
LIMIT 10;

-- Analyze the distribution of post history types and their counts
SELECT 
    pht.Name AS PostHistoryType, 
    COUNT(ph.Id) AS TotalChanges
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalChanges DESC;

-- Compare the number of votes on posts by their type
SELECT 
    pt.Name AS PostType, 
    COUNT(v.Id) AS TotalVotes, 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalVotes DESC;
