
SELECT 
    U.DisplayName AS UserDisplayName,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate, P.Score, P.ViewCount
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
