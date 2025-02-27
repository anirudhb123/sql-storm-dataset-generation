-- Performance benchmarking query for Stack Overflow schema

-- This query aims to retrieve top users based on their reputation and number of posts created, along with their total votes.
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC, TotalPosts DESC
LIMIT 100;  -- Limiting to the top 100 users
