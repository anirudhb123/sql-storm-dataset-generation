
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        @row_num := @row_num + 1 AS ReputationRank
    FROM Users U, (SELECT @row_num := 0) AS r
    WHERE U.Reputation > 0
    ORDER BY U.Reputation DESC
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title, 
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 30 DAY)
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON CAST(PH.Comment AS UNSIGNED) = C.Id
    WHERE PH.PostHistoryTypeId = 10
),
PostStats AS (
    SELECT 
        RP.PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        MAX(RP.Score) AS MaxScore
    FROM RecentPosts RP
    LEFT JOIN Comments C ON RP.PostId = C.PostId
    LEFT JOIN Votes V ON RP.PostId = V.PostId
    GROUP BY RP.PostId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    PS.PostId,
    PS.CommentCount,
    PS.TotalBounties,
    PS.UpVotes,
    PS.DownVotes,
    PS.MaxScore,
    CP.CloseReason
FROM UserReputation UR
JOIN PostStats PS ON UR.UserId = PS.PostId
LEFT JOIN ClosedPosts CP ON PS.PostId = CP.PostId
WHERE UR.ReputationRank <= 10 AND CP.CloseReason IS NOT NULL
ORDER BY UR.Reputation DESC, PS.TotalBounties DESC;
