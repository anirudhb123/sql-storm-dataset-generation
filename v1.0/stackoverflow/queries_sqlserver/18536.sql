
SELECT 
    U.DisplayName, 
    U.Reputation, 
    P.Title, 
    P.CreationDate, 
    P.Score 
FROM 
    Users U 
JOIN 
    Posts P ON U.Id = P.OwnerUserId 
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, 
    U.Reputation, 
    P.Title, 
    P.CreationDate, 
    P.Score 
ORDER BY 
    P.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
