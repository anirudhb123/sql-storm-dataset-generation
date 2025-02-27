WITH UserScoreCTE AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    WHERE U.Reputation > 0
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.Id IS NOT NULL AND V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(NULLIF(P.Score, 0), 1)) AS Score,
        MAX(P.CreationDate) AS LatestPostDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'  -- filtering posts from the last year
    GROUP BY P.Id, P.OwnerUserId
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate >= (NOW() - INTERVAL '6 months')
    GROUP BY PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation AS UserReputation,
    U.UserRank,
    PS.PostId,
    PS.TotalComments,
    PS.UpVotes,
    PS.DownVotes,
    PS.Score,
    COALESCE(PHS.LastEditDate, 'No edits') AS LastEdit,
    PHS.HistoryTypes
FROM UserScoreCTE U
JOIN PostStats PS ON U.UserId = PS.OwnerUserId
LEFT JOIN PostHistorySummary PHS ON PS.PostId = PHS.PostId
WHERE U.Reputation >= 1000  -- Only consider users with a reputation of at least 1000
    AND (PS.TotalComments > 5 OR PS.UpVotes > PS.DownVotes)  -- Filtering posts with significant activity
ORDER BY U.Reputation DESC, PS.Score DESC
LIMIT 50;  -- Limiting to the top 50 results
