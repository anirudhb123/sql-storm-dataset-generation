WITH UserReputation AS (
    SELECT Id, Reputation, 
           CASE 
               WHEN Reputation > 1000 THEN 'High'
               WHEN Reputation > 100 THEN 'Medium'
               ELSE 'Low'
           END AS ReputationLevel
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT L.RelatedPostId) AS RelatedPostsCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks L ON P.Id = L.PostId
    GROUP BY P.Id
),
PostHistoryDetail AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate AS EditDate,
        PH.Comment,
        PHT.Name AS Action
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PHT.Id IN (10, 11, 12, 13)  -- Close, Reopen, Delete, Undelete actions
)
SELECT 
    U.DisplayName,
    U.Views,
    UR.ReputationLevel,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    COUNT(DISTINCT PHD.EditDate) AS EditHistoryCount,
    CASE 
        WHEN PS.Score > 10 THEN 'Highly Engaged'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel,
    STRING_AGG(DISTINCT PHD.Action || ' on ' || PHD.EditDate::date, ', ') AS EditActions
FROM UserReputation UR
JOIN Users U ON UR.Id = U.Id
JOIN PostStatistics PS ON U.Id = PS.PostId
LEFT JOIN PostHistoryDetail PHD ON PS.PostId = PHD.PostId
GROUP BY U.Id, PS.PostId, UR.ReputationLevel
ORDER BY UR.ReputationLevel DESC, PS.Score DESC;
