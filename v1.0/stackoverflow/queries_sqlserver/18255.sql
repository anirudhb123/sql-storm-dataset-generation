
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpvoteCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownvoteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    P.PostTypeId = 1  
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
