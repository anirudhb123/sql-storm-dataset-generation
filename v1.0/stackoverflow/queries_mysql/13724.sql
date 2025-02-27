
SELECT 
    U.Reputation AS UserReputation,
    P.Score AS PostScore,
    P.ViewCount AS PostViewCount,
    P.CreationDate AS PostCreationDate,
    COUNT(C.Id) AS CommentCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
WHERE 
    P.CreationDate > NOW() - INTERVAL 1 YEAR  
GROUP BY 
    U.Reputation, P.Score, P.ViewCount, P.CreationDate
ORDER BY 
    UserReputation DESC, PostScore DESC;
