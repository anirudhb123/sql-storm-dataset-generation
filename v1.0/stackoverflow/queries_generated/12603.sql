-- Performance Benchmarking Query
-- This query retrieves statistics on users, their posts, and the associated tags and votes.
-- It includes aggregation functions to measure performance across different attributes.

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,
    SUM(v.VoteTypeId = 3) AS TotalDownvotes,
    COUNT(DISTINCT t.Id) AS TotalUniqueTags,
    AVG(u.Reputation) AS AverageReputation,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    Tags t ON pl.RelatedPostId = t.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, AverageReputation DESC;
