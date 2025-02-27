SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    SUM(V.VoteTypeId = 2) AS UpVoteCount,
    SUM(V.VoteTypeId = 3) AS DownVoteCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
WHERE 
    P.PostTypeId = 1 -- Only Questions
GROUP BY 
    P.Id, P.Title, P.CreationDate, U.DisplayName
ORDER BY 
    P.CreationDate DESC;
