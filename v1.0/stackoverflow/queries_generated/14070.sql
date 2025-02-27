-- Performance Benchmarking Query for Stack Overflow Schema

-- Get the average view count and score for all posts, grouped by post type
SELECT 
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additionally, measure the number of votes per post type
SELECT 
    pt.Name AS PostTypeName,
    COUNT(v.Id) AS TotalVotes,
    AVG(v.CreationDate) AS AverageVoteDate
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

-- Get the distribution of users' reputation scores
SELECT 
    CASE 
        WHEN Reputation < 100 THEN 'Low Reputation'
        WHEN Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
        WHEN Reputation > 1000 THEN 'High Reputation'
    END AS ReputationCategory,
    COUNT(Id) AS UserCount
FROM 
    Users
GROUP BY 
    ReputationCategory
ORDER BY 
    UserCount DESC;

-- Measure the time taken to publish a post by user reputation
SELECT 
    u.Reputation,
    AVG(EXTRACT(EPOCH FROM (p.CreationDate - u.CreationDate))) AS AverageTimeToPost
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    u.Reputation
ORDER BY 
    u.Reputation;
