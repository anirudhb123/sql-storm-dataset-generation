-- Performance Benchmarking Query on StackOverflow Schema

-- This query retrieves the count of posts by type, average view count, 
-- and total votes for each post type, along with user reputation who created these posts.

SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViewCount,
    SUM(vote_count) AS TotalVotes
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN (
    SELECT 
        PostId, 
        COUNT(*) AS vote_count
    FROM 
        Votes
    GROUP BY 
        PostId
) v ON p.Id = v.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;
