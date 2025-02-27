
SELECT 
    P.Id AS PostId,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation AS OwnerReputation,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS DownVoteCount,
    PH.PostHistoryTypeId,
    PH.CreationDate AS HistoryDate,
    PH.Comment AS HistoryComment
FROM 
    Posts P
JOIN 
    Users U ON P.OwnerUserId = U.Id
LEFT JOIN 
    PostHistory PH ON PH.PostId = P.Id
WHERE 
    P.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
GROUP BY 
    P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, 
    U.DisplayName, U.Reputation, 
    PH.PostHistoryTypeId, PH.CreationDate, PH.Comment
ORDER BY 
    P.CreationDate DESC
LIMIT 100;
