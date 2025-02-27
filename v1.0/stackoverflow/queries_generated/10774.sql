-- Performance benchmarking SQL query
-- This query calculates the total number of posts, average score, and the total views grouped by post type.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additionally, we can check the average reputation of users who created posts.

SELECT 
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.OwnerUserId IS NOT NULL;

-- This query retrieves the count of votes and the top 5 voted posts.

SELECT 
    p.Title,
    COUNT(v.Id) AS VoteCount
FROM 
    Votes v
JOIN 
    Posts p ON v.PostId = p.Id
GROUP BY 
    p.Title
ORDER BY 
    VoteCount DESC
LIMIT 5;

-- Lastly, benchmarking the average time to edit by post type

SELECT 
    pt.Name AS PostType,
    AVG(EXTRACT(EPOCH FROM (ph.CreationDate - p.LastEditDate))) AS AverageEditTimeInSeconds
FROM 
    PostHistory ph
JOIN 
    Posts p ON ph.PostId = p.Id
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    pht.Name LIKE 'Edit%'
GROUP BY 
    pt.Name;
