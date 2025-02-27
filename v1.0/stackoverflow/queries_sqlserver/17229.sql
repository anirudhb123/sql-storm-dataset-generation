
SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    C.Text AS CommentText,
    C.CreationDate AS CommentCreationDate
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    C.Text,
    C.CreationDate
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
