
SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.ViewCount,
    P.Score
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.ViewCount, P.Score
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
