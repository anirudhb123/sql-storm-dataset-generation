-- Performance Benchmarking Query

SELECT 
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(DISTINCT C.Id) AS CommentCount,
    SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
    SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
    P.Score,
    P.ViewCount,
    T.TagName,
    B.Name AS BadgeName,
    PH.CreationDate AS PostHistoryDate,
    PH.Comment AS PostHistoryComment
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    Comments C ON P.Id = C.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    Tags T ON T.Id = P.Tags::int[] -- Assuming Tags is a stored array or that Tags field can be processed to extract IDs
LEFT JOIN 
    Badges B ON U.Id = B.UserId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.CreationDate >= '2023-01-01' 
GROUP BY 
    P.Title, 
    P.CreationDate, 
    U.DisplayName, 
    P.Score, 
    P.ViewCount, 
    T.TagName, 
    B.Name, 
    PH.CreationDate, 
    PH.Comment
ORDER BY 
    P.CreationDate DESC;
