-- Performance Benchmarking SQL query

-- This query retrieves the count of Posts and their corresponding average scores, grouped by PostTypeId.
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;

-- Additionally, we can analyze user contributions by counting the number of posts per user and 
-- their total upvotes received.
SELECT 
    u.DisplayName,
    COUNT(p.Id) AS TotalPostsByUser,
    SUM(p.UpVotes) AS TotalUpVotes
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalPostsByUser DESC;

-- Finally, we'll benchmark the most common close reasons and the number of posts closed by each reason.
SELECT 
    cht.Name AS CloseReason,
    COUNT(ph.Id) AS TotalCloseReasons
FROM 
    PostHistory ph
JOIN 
    PostHistoryTypes cht ON ph.PostHistoryTypeId = cht.Id
WHERE 
    cht.Id IN (10, 11) -- 10 = Post Closed, 11 = Post Reopened
GROUP BY 
    cht.Name
ORDER BY 
    TotalCloseReasons DESC;
