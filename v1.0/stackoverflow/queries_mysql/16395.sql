
SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    P.Body 
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
    P.Body 
ORDER BY 
    P.CreationDate DESC 
LIMIT 10;
