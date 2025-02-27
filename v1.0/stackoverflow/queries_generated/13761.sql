-- Performance benchmarking query for Stack Overflow schema

-- This query evaluates the average post view count, average score, and total number of posts by each user.
-- It joins the Posts and Users tables to aggregate the data.

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(P.Id) AS TotalPosts,
    AVG(P.ViewCount) AS AverageViewCount,
    AVG(P.Score) AS AverageScore
FROM 
    Users U
LEFT JOIN 
    Posts P ON U.Id = P.OwnerUserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalPosts DESC;
