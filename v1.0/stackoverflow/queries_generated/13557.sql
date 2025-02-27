-- Performance benchmarking query for the StackOverflow schema
-- This query retrieves the number of posts created by each user along with their average reputation,
-- and total votes cast on their posts, sorted by the number of posts in descending order.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS NumberOfPosts,
    AVG(U.Reputation) AS AverageReputation,
    SUM(V.TotalVotes) AS TotalVotes
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    (SELECT 
         PostId,
         COUNT(*) AS TotalVotes
     FROM 
         Votes
     GROUP BY 
         PostId) V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    NumberOfPosts DESC;
