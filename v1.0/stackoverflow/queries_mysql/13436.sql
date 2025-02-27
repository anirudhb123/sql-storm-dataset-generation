
SELECT 
    P.Title,
    P.ViewCount,
    U.Reputation,
    P.AnswerCount,
    P.CreationDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Title, P.ViewCount, U.Reputation, P.AnswerCount, P.CreationDate
ORDER BY 
    P.ViewCount DESC
LIMIT 10;
