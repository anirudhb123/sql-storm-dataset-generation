-- Performance Benchmarking Query

-- This query retrieves the number of posts, comments, and votes per user along with their reputation, 
-- allowing for benchmarking of user engagement on the platform.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(DISTINCT P.Id) AS PostCount,
    COUNT(DISTINCT C.Id) AS CommentCount,
    COUNT(DISTINCT V.Id) AS VoteCount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON U.Id = C.UserId
LEFT JOIN 
    Votes V ON U.Id = V.UserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    U.Reputation DESC, PostCount DESC, CommentCount DESC, VoteCount DESC;
