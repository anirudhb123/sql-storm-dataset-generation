
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score AS PostScore,
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    AVG(P.Score) OVER() AS AveragePostScore,
    COUNT(*) OVER() AS TotalPosts
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY
    P.Id,
    P.Title,
    P.CreationDate,
    P.Score,
    U.Id,
    U.DisplayName,
    U.Reputation
ORDER BY 
    P.CreationDate DESC;
