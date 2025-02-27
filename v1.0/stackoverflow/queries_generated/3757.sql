WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
),
PostActivity AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(PH.UserId, -1) AS LastEditedBy,
        PH.LastEditDate,
        RANK() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) -- Edit Title and Body
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'
),
PostSummary AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.Score + COALESCE(SUM(VB.BountyAmount), 0) AS AdjustedScore,
        PA.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM PostActivity PA
    LEFT JOIN Votes VB ON PA.PostId = VB.PostId AND VB.VoteTypeId = 9 -- BountyClose
    LEFT JOIN Comments C ON PA.PostId = C.PostId
    GROUP BY PA.PostId, PA.Title, PA.Score, PA.ViewCount
)
SELECT 
    PS.Title,
    PS.AdjustedScore,
    PS.ViewCount,
    COALESCE(U.DisplayName, 'Anonymous') AS LastEditorDisplayName,
    U.UpVotes AS TotalUpVotes,
    U.DownVotes AS TotalDownVotes,
    U.TotalBounty
FROM PostSummary PS
LEFT JOIN UserVoteStats U ON PS.AdjustedScore > 10 AND U.UserId = PS.PostId 
WHERE PS.CommentCount > 0
ORDER BY PS.AdjustedScore DESC, PS.ViewCount DESC
LIMIT 50;
