WITH UserVoteSummary AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostScores AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(PH.UserId, -1) AS LastEditorId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.LastActivityDate DESC) AS Rank
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.LastEditorUserId = PH.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    UPS.UpVotes,
    UPS.DownVotes,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.Score AS PostScore,
    PS.ViewCount AS PostViewCount,
    CASE 
        WHEN PS.Rank = 1 THEN 'Most Active'
        ELSE 'Active'
    END AS ActivityStatus,
    CASE 
        WHEN U.Reputation IS NULL THEN 'No Reputation'
        ELSE CONVERT(varchar, U.Reputation)
    END AS ReputationDisplay
FROM Users U
JOIN UserVoteSummary UPS ON U.Id = UPS.UserId
LEFT JOIN PostScores PS ON U.Id = PS.LastEditorId
WHERE 
    UPS.TotalVotes > 0
    OR U.Reputation > 100
ORDER BY 
    UPS.TotalVotes DESC,
    U.Reputation DESC;
