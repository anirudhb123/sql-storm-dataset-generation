-- Performance Benchmarking Query

-- This query fetches user information along with their posts and comments,
-- measuring the count of posts, count of comments, and average reputation
-- to assess performance metrics.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate,
    COUNT(DISTINCT P.Id) AS PostCount,
    COUNT(DISTINCT C.Id) AS CommentCount,
    AVG(V.BountyAmount) AS AvgBountyAmount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
ORDER BY 
    U.Reputation DESC
LIMIT 100; -- Limiting to top 100 users with the highest reputation
