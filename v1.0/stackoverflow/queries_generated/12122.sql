-- Performance benchmarking query to retrieve users with the highest reputation and their associated posts, along with the total votes received on those posts.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS TotalPosts,
    SUM(V.VoteTypeId = 2) AS TotalUpVotes,  -- UpVotes
    SUM(V.VoteTypeId = 3) AS TotalDownVotes, -- DownVotes
    SUM(P.Score) AS TotalScore
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC
LIMIT 10;
