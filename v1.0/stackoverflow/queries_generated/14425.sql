-- Performance benchmarking query for Stack Overflow schema
-- This query retrieves the number of posts created by each user along with their reputation
-- It will help evaluate the performance impact of the join operations on Users and Posts tables

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    COUNT(P.Id) AS PostCount
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName, U.Reputation
ORDER BY 
    PostCount DESC;
