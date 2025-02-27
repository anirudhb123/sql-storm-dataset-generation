WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRow
    FROM Posts P
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
), 
PostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        U.DisplayName AS OwnerName,
        COALESCE(SUM(V.BountyAmount) FILTER (WHERE V.VoteTypeId = 9), 0) AS TotalBounty,  -- BountyClose
        CASE 
            WHEN RP.Score IS NULL THEN 'No Score'
            WHEN RP.Score > 0 THEN 'Positive Score'
            ELSE 'Negative Score'
        END AS ScoreCategory
    FROM RecentPosts RP
    LEFT JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN Votes V ON RP.PostId = V.PostId
    WHERE RP.PostRow = 1
    GROUP BY RP.PostId, RP.Title, RP.OwnerUserId, U.DisplayName, RP.Score
), 
PostHistoryData AS (
    SELECT 
        PH.PostId,
        PHT.Name AS HistoryType,
        COUNT(*) AS HistoryCount
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate >= NOW() - INTERVAL '365 days'
    GROUP BY PH.PostId, PHT.Name
)

SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.OwnerName,
    PD.TotalBounty,
    PD.ScoreCategory,
    PH.HistoryCount AS PostHistoryCount,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PD.PostId) AS CommentCount
FROM UserReputation UR
JOIN PostDetails PD ON UR.UserId = PD.OwnerUserId
LEFT JOIN PostHistoryData PH ON PD.PostId = PH.PostId
WHERE UR.ReputationRank <= 100
AND (PD.Score > 10 OR PD.TotalBounty > 0)
ORDER BY UR.Reputation DESC, PD.CreationDate DESC
LIMIT 50;
