-- Performance benchmarking query for StackOverflow schema

-- Aggregating user statistics for users who have made posts
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    COUNT(DISTINCT C.Id) AS TotalComments,
    SUM(V.VoteTypeId = 2) AS TotalUpVotes,
    SUM(V.VoteTypeId = 3) AS TotalDownVotes,
    SUM(B.Id IS NOT NULL) AS TotalBadges
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    U.Reputation > 0 -- considering only users with reputation
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    TotalPosts DESC, U.Reputation DESC
LIMIT 100; -- Limit to top 100 users for benchmarking
