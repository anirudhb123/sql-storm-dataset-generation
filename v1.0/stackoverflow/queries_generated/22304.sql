WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unrated User'
            WHEN Reputation < 100 THEN 'Low Reputation'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Moderate Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM Users
),

PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COUNT(CASE WHEN COALESCE(V.UserId, 0) <> 0 THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer,
        AVG(P.Score) OVER (PARTITION BY P.OwnerUserId) AS AVGScore
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.PostTypeId
),

PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.UserId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RevisionCount,
        MAX(PH.CreationDate) OVER (PARTITION BY PH.PostId) AS LatestEditDate
    FROM PostHistory PH
)

SELECT 
    U.DisplayName AS UserDisplayName,
    U.Reputation,
    UR.ReputationCategory,
    P.PostId,
    P.HasAcceptedAnswer,
    P.VoteCount,
    P.CommentCount,
    P.AVGScore,
    PH.RevisionCount,
    PH.LatestEditDate,
    PH.Comment,
    STRING_AGG(CASE WHEN T.TagName IS NOT NULL THEN T.TagName ELSE 'Untagged' END, ', ') AS Tags
FROM Users U
JOIN UserReputation UR ON U.Id = UR.UserId
JOIN PostStatistics P ON U.Id = P.OwnerUserId
LEFT JOIN PostHistoryDetails PH ON P.PostId = PH.PostId
LEFT JOIN Posts Po ON P.PostId = Po.Id
LEFT JOIN LATERAL (
    SELECT 
        UNNEST(string_to_array(Po.Tags, ',')) AS TagName
) AS T ON TRUE
WHERE 
    (UR.ReputationCategory = 'High Reputation' AND P.HasAcceptedAnswer = 1) OR 
    (UR.ReputationCategory = 'Low Reputation' AND P.VoteCount < 5)
GROUP BY 
    U.DisplayName, U.Reputation, UR.ReputationCategory, P.PostId, 
    P.HasAcceptedAnswer, P.VoteCount, P.CommentCount, P.AVGScore,
    PH.RevisionCount, PH.LatestEditDate
ORDER BY 
    U.Reputation DESC, P.AVGScore DESC, PH.LatestEditDate DESC
LIMIT 100;

