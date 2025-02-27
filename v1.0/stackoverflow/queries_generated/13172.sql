-- Performance Benchmarking SQL Query

-- This query retrieves various metrics including post types, user reputation, and post activity.
SELECT 
    pt.Name AS PostType,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(p.ViewCount) AS TotalViews,
    SUM(COALESCE(v.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(v.DownVotes, 0)) AS TotalDownVotes,
    AVG(u.Reputation) AS AverageUserReputation,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId 
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
