
SELECT 
    U.DisplayName AS UserDisplayName, 
    P.Title AS PostTitle, 
    P.CreationDate AS PostCreationDate, 
    P.Score AS PostScore 
FROM 
    Posts P 
JOIN 
    Users U ON P.OwnerUserId = U.Id 
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Score 
ORDER BY 
    P.Score DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
