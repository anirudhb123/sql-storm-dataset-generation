WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT V.UserId) AS UniqueVoters
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserDisplayName,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM PostHistory PH
    WHERE PH.CreationDate > NOW() - INTERVAL '30 days'
)
SELECT 
    P.Id AS PostId,
    P.Title,
    U.DisplayName AS OwnerDisplayName,
    COALESCE(SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS TotalCloseVotes,
    PS.CommentCount,
    PS.UpVotes,
    PS.DownVotes,
    UR.Reputation,
    UR.ReputationRank
FROM Posts P
JOIN UserReputation UR ON P.OwnerUserId = UR.UserId
LEFT JOIN PostStatistics PS ON P.Id = PS.PostId
LEFT JOIN RecentPostHistory PH ON P.Id = PH.PostId AND PH.HistoryRank = 1
WHERE 
    P.CreationDate > NOW() - INTERVAL '1 year' 
    AND (PS.CommentCount > 0 OR UR.Reputation < 100)
GROUP BY 
    P.Id, P.Title, U.DisplayName, UR.Reputation, UR.ReputationRank
HAVING 
    (SUM(PS.UpVotes) - SUM(PS.DownVotes)) > 10
ORDER BY 
    UR.Reputation DESC, P.Title;
