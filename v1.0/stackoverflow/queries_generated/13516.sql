SELECT 
    P.Id AS PostId,
    P.Title,
    P.ViewCount,
    P.Score,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Comment) AS TotalComments,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, P.ViewCount, P.Score, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
