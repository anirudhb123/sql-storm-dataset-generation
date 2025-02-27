WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(B.Reputation, 0)) AS TotalReputation
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN (
        SELECT UserId, SUM(Reputation) AS Reputation
        FROM Users
        GROUP BY UserId
    ) B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(COALESCE(V.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 -- Closed posts
    GROUP BY PH.PostId
)

SELECT 
    U.DisplayName AS UserName,
    U.UpVotes AS UserUpVotes,
    U.DownVotes AS UserDownVotes,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.CommentCount,
    PS.TotalScore,
    COALESCE(CP.CloseCount, 0) AS PostCloseCount,
    CASE 
        WHEN PS.PostRank = 1 THEN 'Recent Post'
        ELSE 'Older Post'
    END AS PostCategory
FROM UserVoteSummary U
JOIN PostSummary PS ON U.UserId = PS.OwnerUserId
LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
WHERE PS.TotalScore > 0 
AND PS.CommentCount > 5 
AND U.TotalReputation > 100
ORDER BY U.UpVotes DESC, PS.CreationDate DESC;

