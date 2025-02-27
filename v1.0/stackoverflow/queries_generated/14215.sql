SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(C.Id) AS CommentCount,
    SUM(V.VoteTypeId = 2) AS UpVotes,
    SUM(V.VoteTypeId = 3) AS DownVotes,
    PT.Name AS PostType,
    PH.CreationDate AS LastEditDate
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    PostTypes PT ON P.PostTypeId = PT.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
GROUP BY 
    P.Id, U.DisplayName, PT.Name, PH.CreationDate
ORDER BY 
    P.CreationDate DESC;
