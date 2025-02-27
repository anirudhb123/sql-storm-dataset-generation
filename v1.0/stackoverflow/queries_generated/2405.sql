WITH UserVoteCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(U.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COUNT(C) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.OwnerUserId, U.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate,
        PT.Name AS HistoryType
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
)
SELECT 
    P.Title,
    P.CreationDate,
    PS.OwnerDisplayName,
    PS.CommentCount,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    (SELECT COUNT(PH.PostId)
     FROM PostHistoryInfo PHI
     WHERE PHI.PostId = PS.PostId AND PHI.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
    (SELECT COUNT(DISTINCT PL.RelatedPostId)
     FROM PostLinks PL
     WHERE PL.PostId = PS.PostId AND PL.LinkTypeId = 3) AS DuplicateLinkCount
FROM 
    PostStats PS
JOIN 
    Posts P ON PS.PostId = P.Id
LEFT JOIN 
    Users U ON P.OwnerUserId = U.Id
WHERE 
    PS.TotalVotes > 0
ORDER BY 
    PS.TotalUpVotes DESC, PS.CommentCount DESC
LIMIT 50;
