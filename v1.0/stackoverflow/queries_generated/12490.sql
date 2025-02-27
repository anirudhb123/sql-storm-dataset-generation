-- Performance Benchmarking Query for StackOverflow Schema

-- This query benchmarks the average and total number of votes, posts, and comments made by each user
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    AVG(v.BountyAmount) AS AverageBountyAmount,
    SUM(v.BountyAmount) AS TotalBountyAmount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON u.Id = c.UserId
LEFT JOIN 
    Votes v ON u.Id = v.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, TotalComments DESC;
