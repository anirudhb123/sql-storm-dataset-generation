-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the count of posts, average views, and total upvotes for each post type, along with the user reputations of the owners.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AverageViewCount,
    SUM(p.UpVotes) AS TotalUpVotes,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
