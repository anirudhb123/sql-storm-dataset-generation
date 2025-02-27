-- Performance Benchmarking SQL Query

-- This query retrieves statistics on post activity, user engagement, and vote counts to assess performance
SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
    SUM(p.ViewCount) AS TotalViews,
    COUNT(c.Id) AS TotalComments,
    SUM(v.VoteTypeId = 2) AS TotalUpvotes,
    SUM(v.VoteTypeId = 3) AS TotalDownvotes,
    AVG(u.Reputation) AS AvgUserReputation,
    COUNT(DISTINCT u.Id) AS UniqueUsersEngaged
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 YEAR'  -- Limiting to the last year for benchmarking
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;
