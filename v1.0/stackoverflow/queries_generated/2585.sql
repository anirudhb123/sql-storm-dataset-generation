WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        MAX(P.CreationDate) AS LastPostDate
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserPostStats
    WHERE PostCount > 5
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RN
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
)

SELECT 
    T.DisplayName,
    T.TotalScore,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.OwnerName
FROM TopUsers T
LEFT JOIN RecentPosts R ON T.UserId = R.OwnerUserId
WHERE T.ScoreRank <= 10 
  AND R.RN = 1
ORDER BY T.TotalScore DESC, R.CreationDate DESC;

-- This query includes outer joins, CTEs for user post statistics, ranking users based on scores, 
-- and recent posts filtering, showcasing their latest contributions.
