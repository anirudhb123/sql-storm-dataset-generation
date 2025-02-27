SELECT 
    U.DisplayName AS UserName,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
    COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags,
    COUNT(DISTINCT B.Id) AS BadgeCount
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    STRING_TO_ARRAY(P.Tags, ',') AS T
WHERE 
    P.CreationDate >= NOW() - INTERVAL '1 YEAR'
GROUP BY 
    U.DisplayName, P.Title, P.CreationDate
HAVING 
    COUNT(DISTINCT C.Id) > 5
ORDER BY 
    UpVotes DESC, DownVotes ASC, P.CreationDate DESC
LIMIT 10;
