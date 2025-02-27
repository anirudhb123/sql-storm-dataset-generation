
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) AS VoteCount,
    P.LastActivityDate,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditor
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.PostTypeId = 1 
GROUP BY 
    P.Id,
    P.Title,
    P.CreationDate,
    P.Score,
    P.ViewCount,
    U.DisplayName,
    U.Reputation,
    P.LastActivityDate,
    PH.CreationDate,
    PH.UserDisplayName
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
