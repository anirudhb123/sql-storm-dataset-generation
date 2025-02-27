-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the count of posts, average score, and total views by post type,
-- along with user reputation and badge count, to assess system performance on data aggregation and joins.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    AVG(p.Score) AS AverageScore,
    SUM(p.ViewCount) AS TotalViews,
    u.Reputation AS UserReputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    pt.Name, u.Reputation
ORDER BY 
    PostCount DESC;
