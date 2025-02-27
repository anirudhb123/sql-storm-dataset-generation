
SELECT 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    V.VoteTypeId 
FROM 
    Posts P 
JOIN 
    Users U ON P.OwnerUserId = U.Id 
JOIN 
    Votes V ON P.Id = V.PostId 
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName, 
    P.Title, 
    P.CreationDate, 
    V.VoteTypeId 
ORDER BY 
    P.CreationDate DESC 
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
