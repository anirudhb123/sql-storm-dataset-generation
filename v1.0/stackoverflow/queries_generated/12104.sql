-- Performance benchmarking query for the StackOverflow schema

-- This query retrieves the count of posts, average score, and view count for questions grouped by user reputation.
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS PostCount,
    AVG(P.Score) AS AverageScore,
    AVG(P.ViewCount) AS AverageViewCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
WHERE 
    P.PostTypeId = 1 -- Only questions
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    PostCount DESC
LIMIT 100; -- Limit to top 100 users based on post count
