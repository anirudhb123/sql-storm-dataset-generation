
WITH UserReputation AS (
    SELECT
        Id AS UserId,
        Reputation,
        CASE
            WHEN Reputation <= 100 THEN 'Newbie'
            WHEN Reputation <= 1000 THEN 'Novice'
            WHEN Reputation <= 5000 THEN 'Intermediate'
            ELSE 'Expert' 
        END AS ReputationLevel
    FROM Users
),
PopularPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        @row_number := IF(@prev_user = P.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @prev_user := P.OwnerUserId
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    CROSS JOIN (SELECT @row_number := 0, @prev_user := NULL) AS init
    WHERE P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
ClosedPostHistory AS (
    SELECT
        PH.PostId,
        MIN(PH.CreationDate) AS FirstCloseDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11, 12)
    GROUP BY PH.PostId
),
AggregateCloseReasons AS (
    SELECT
        PH.PostId,
        GROUP_CONCAT(DISTINCT CRT.Name) AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CRT ON PH.Comment = CAST(CRT.Id AS CHAR) AND PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT
    URE.UserId,
    URE.Reputation,
    URE.ReputationLevel,
    PP.PostId,
    PP.Title,
    PP.CreationDate,
    PP.ViewCount,
    PP.Score,
    PP.TotalBounty,
    CPH.FirstCloseDate,
    ACR.CloseReasons
FROM UserReputation URE
JOIN PopularPosts PP ON PP.PostId = (
    SELECT P.Id
    FROM Posts P
    WHERE P.OwnerUserId = URE.UserId 
    ORDER BY P.ViewCount DESC 
    LIMIT 1
)
LEFT JOIN ClosedPostHistory CPH ON PP.PostId = CPH.PostId
LEFT JOIN AggregateCloseReasons ACR ON PP.PostId = ACR.PostId
WHERE URE.Reputation > 500
  AND PP.PostRank = 1 
ORDER BY URE.Reputation DESC, PP.ViewCount DESC
LIMIT 50;
