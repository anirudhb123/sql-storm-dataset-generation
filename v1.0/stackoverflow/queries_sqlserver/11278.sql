
SELECT 
    U.Id AS UserId,
    U.Reputation,
    P.Title,
    COUNT(C.Id) AS CommentCount
FROM 
    Users U
JOIN 
    Posts P ON U.Id = P.OwnerUserId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
GROUP BY 
    U.Id, U.Reputation, P.Title
ORDER BY 
    U.Reputation DESC, CommentCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
