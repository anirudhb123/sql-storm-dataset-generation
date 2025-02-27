-- Performance Benchmarking Query

-- Count the number of posts for each post type along with the average score and average view count
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    AVG(p.ViewCount) AS AverageViewCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Aggregate user statistics including reputation and total posts created
SELECT 
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC;

-- Track the number of comments per post type
SELECT 
    pt.Name AS PostType,
    COUNT(c.Id) AS TotalComments
FROM 
    Comments c
JOIN 
    Posts p ON c.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalComments DESC;

-- Measure badge distribution across users
SELECT 
    b.Name AS BadgeName,
    COUNT(b.Id) AS TotalAwarded
FROM 
    Badges b
GROUP BY 
    b.Name
ORDER BY 
    TotalAwarded DESC;

-- Analyze average time between post creation and closed date
SELECT 
    pt.Name AS PostType,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.CreationDate)) / 3600) AS AverageHoursToClose
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    pht.Name = 'Post Closed'
GROUP BY 
    pt.Name;
