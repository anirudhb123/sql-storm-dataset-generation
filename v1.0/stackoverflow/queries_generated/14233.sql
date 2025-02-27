-- Performance benchmarking query to analyze post activities and user engagement
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    COUNT(CM.Id) AS TotalComments,
    COUNT(V.Id) AS TotalVotes,
    SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
    P.ViewCount,
    P.Score,
    P.AnswerCount,
    P.CommentCount,
    PH.CreationDate AS LastEditDate,
    PH.UserDisplayName AS LastEditor
FROM 
    Posts P
LEFT JOIN 
    Comments CM ON P.Id = CM.PostId
LEFT JOIN 
    Votes V ON P.Id = V.PostId
LEFT JOIN 
    VoteTypes VT ON V.VoteTypeId = VT.Id
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId
WHERE 
    P.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days')  -- Filter for posts created in the last 30 days
GROUP BY 
    P.Id, 
    U.DisplayName, 
    PH.CreationDate, 
    PH.UserDisplayName
ORDER BY 
    P.CreationDate DESC;
