
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        @row_num := @row_num + 1 AS ReputationRank
    FROM Users U, (SELECT @row_num := 0) r
    WHERE U.Reputation > 1000
    ORDER BY U.Reputation DESC
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.OwnerUserId, P.CreationDate, P.Title, P.Score, P.ViewCount
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        UR.UserId,
        UR.DisplayName,
        UR.ReputationRank
    FROM RecentPosts RP
    JOIN UserReputation UR ON RP.OwnerUserId = UR.UserId
    WHERE RP.Score > 10
),
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY PH.PostId
)
SELECT 
    TP.Title,
    TP.Score,
    TP.ViewCount,
    TP.DisplayName,
    TP.ReputationRank,
    PH.EditCount,
    PH.LastEditedDate,
    CASE 
        WHEN PH.EditCount IS NULL THEN 'No Edits'
        ELSE 'Edited'
    END AS EditStatus
FROM TopPosts TP
LEFT JOIN PostHistories PH ON TP.PostId = PH.PostId
WHERE TP.ReputationRank <= 10 
ORDER BY TP.Score DESC, TP.ViewCount DESC;
