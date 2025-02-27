-- Performance benchmark query to retrieve the top 10 users with the highest reputation and their post counts
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COUNT(p.Id) AS PostCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, u.Reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Performance benchmark query to count the number of blog posts by type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount
FROM 
    PostTypes pt
LEFT JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
ORDER BY 
    PostCount DESC;

-- Performance benchmark query to retrieve the latest posts and their associated tags
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Tags
FROM 
    Posts p
WHERE 
    p.CreationDate >= NOW() - INTERVAL '30 days'
ORDER BY 
    p.CreationDate DESC
LIMIT 20;

-- Performance benchmark query to examine the average score of posts by type
SELECT 
    pt.Name AS PostType,
    AVG(p.Score) AS AverageScore
FROM 
    PostTypes pt
JOIN 
    Posts p ON pt.Id = p.PostTypeId
GROUP BY 
    pt.Name
ORDER BY 
    AverageScore DESC;
