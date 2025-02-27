-- Performance Benchmarking SQL Query

-- This query retrieves the average view count of posts grouped by post type
-- along with the total number of posts and their average score for performance analysis.

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

-- This query evaluates user activity based on the number of posts and comments created
-- returning the users with the highest engagement metrics.

SELECT 
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS PostCount,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
GROUP BY 
    u.Id
ORDER BY 
    PostCount DESC, CommentCount DESC;

-- This final query checks the change history of posts to identify the most active posts
-- by the number of edit actions recorded in the PostHistory table.

SELECT 
    p.Title,
    COUNT(ph.Id) AS EditActions,
    MAX(ph.CreationDate) AS LastEdited
FROM 
    Posts p
JOIN 
    PostHistory ph ON p.Id = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Edits of title, body, tags, and suggested edits
GROUP BY 
    p.Id, p.Title
ORDER BY 
    EditActions DESC, LastEdited DESC;
