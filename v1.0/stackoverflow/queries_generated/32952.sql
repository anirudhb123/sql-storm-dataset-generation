WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level,
        CAST(U.DisplayName AS VARCHAR(100)) AS DisplayName
    FROM Users U
    WHERE U.Reputation > 1000
    UNION ALL
    SELECT 
        U.Id,
        U.Reputation,
        UR.Level + 1,
        CAST(CONCAT(UR.DisplayName, ' - ', U.DisplayName) AS VARCHAR(100))
    FROM Users U
    JOIN UserReputation UR ON U.Reputation < UR.Reputation
    WHERE UR.Level < 5
),
PostAggregates AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(P.Score) AS TotalScore,
        AVG(COALESCE(P.ViewCount, 0)) AS AverageViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UR.Reputation,
        PA.TotalPosts,
        PA.TotalScore,
        PA.AverageViewCount,
        PA.LastPostDate
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostAggregates PA ON U.Id = PA.OwnerUserId
    WHERE UR.Level = 1
),
PostHistoryWithCloseReasons AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN CH.Name END) AS CloseReason,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END) AS DeletionCount
    FROM PostHistory PH
    LEFT JOIN CloseReasonTypes CH ON PH.Comment::int = CH.Id
    GROUP BY PH.PostId
),
UserPostStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PA.TotalPosts, 0) AS TotalPosts,
        COALESCE(PA.TotalScore, 0) AS TotalScore,
        COALESCE(PH.CloseReason, 'No Close Reason') AS CloseReason,
        COALESCE(PH.DeletionCount, 0) AS DeletionCount
    FROM Users U
    LEFT JOIN PostAggregates PA ON U.Id = PA.OwnerUserId
    LEFT JOIN PostHistoryWithCloseReasons PH ON PH.PostId IN (
        SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id
    )
    WHERE U.Reputation > 100
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    UPS.TotalPosts,
    UPS.TotalScore,
    UPS.CloseReason,
    UPS.DeletionCount,
    ROW_NUMBER() OVER (ORDER BY TU.Reputation DESC) AS Rank
FROM TopUsers TU
JOIN UserPostStatistics UPS ON TU.Id = UPS.UserId
ORDER BY TU.Reputation DESC
LIMIT 50;

