-- Performance Benchmarking Query
-- This query is designed to measure the performance of join operations, aggregation, and filtering on the Stack Overflow schema.

-- Retrieving user reputation data along with their posts, votes, and badges
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT V.Id) AS TotalVotes,
    COUNT(DISTINCT B.Id) AS TotalBadges,
    AVG(V.BountyAmount) AS AverageBounty -- Assuming BountyAmount is for BountyStart votes only
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId 
LEFT JOIN 
    Votes V ON P.Id = V.PostId 
LEFT JOIN 
    Badges B ON U.Id = B.UserId 
WHERE 
    U.Reputation > 1000 -- Filtering for users with a reputation greater than 1000
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, U.Reputation DESC
LIMIT 100; -- Limit results for better performance
