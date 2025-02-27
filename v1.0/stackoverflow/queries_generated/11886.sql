-- Performance benchmarking query for the StackOverflow schema

-- Calculate the total number of posts, average score, and maximum view count per post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    MAX(p.ViewCount) AS MaxViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Evaluate the number of comments and average votes per user
SELECT 
    u.DisplayName AS UserName,
    COUNT(c.Id) AS TotalComments,
    SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
    AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpvotes
FROM 
    Users u
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.DisplayName
HAVING 
    COUNT(c.Id) > 0
ORDER BY 
    TotalVotes DESC;

-- Analyze badge distribution among users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalAwarded,
    MIN(u.Reputation) AS MinReputation,
    AVG(u.Reputation) AS AvgReputation,
    MAX(u.Reputation) AS MaxReputation
FROM 
    Badges b
JOIN 
    Users u ON b.UserId = u.Id
GROUP BY 
    b.Name
ORDER BY 
    TotalAwarded DESC;

-- Performance by post history operations
SELECT 
    pht.Name AS PostHistoryType,
    COUNT(ph.Id) AS TotalChanges,
    MAX(ph.CreationDate) AS LastChangeDate
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
GROUP BY 
    pht.Name
ORDER BY 
    TotalChanges DESC;
