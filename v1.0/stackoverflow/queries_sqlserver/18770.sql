
SELECT 
    P.Title AS PostTitle,
    U.DisplayName AS OwnerName,
    P.CreationDate,
    P.ViewCount,
    P.AnswerCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Title, U.DisplayName, P.CreationDate, P.ViewCount, P.AnswerCount
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
