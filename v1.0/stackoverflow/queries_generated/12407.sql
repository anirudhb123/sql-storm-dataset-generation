-- Performance Benchmarking Query for StackOverflow Schema

-- This query retrieves the total number of posts, average score of posts, and total number of votes while joining necessary tables to get relevant information.

SELECT 
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore,
    COUNT(v.Id) AS TotalVotes,
    ut.Name AS UserTypeName,
    COUNT(DISTINCT u.Id) AS TotalUsers
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserTypes ut ON u.AccountId = ut.Id
WHERE 
    p.CreationDate >= NOW() - INTERVAL '1 year' -- filter for posts created in the last year
GROUP BY 
    ut.Name; -- Group by user type if needed
