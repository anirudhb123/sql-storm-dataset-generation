-- Performance Benchmarking Query

-- This query retrieves the count of posts created by each user along with the average score of their posts, 
-- performing a join between Posts and Users, and grouping by the user.
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AveragePostScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    U.Reputation > 100 -- Filter to include only users with a reputation greater than 100
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC; -- Ordering by the number of posts in descending order
