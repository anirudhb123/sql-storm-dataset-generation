SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.*) AS CommentCount,
    SUM(V.VoteTypeId = 2) AS UpVotes,
    SUM(V.VoteTypeId = 3) AS DownVotes
FROM 
    Posts P
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC
LIMIT 10;
