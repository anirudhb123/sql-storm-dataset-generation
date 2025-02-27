
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(P.Score) AS AvgScore,
        MAX(P.CreationDate) AS LastPostDate
    FROM Posts P
    WHERE P.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.PostHistoryTypeId = 10 AND PH.Comment IS NOT NULL
    WHERE PH.CreationDate > DATEADD(month, -6, '2024-10-01 12:34:56')
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    R.TotalPosts,
    R.Questions,
    R.Answers,
    COALESCE(CP.CloseReason, 'No closure') AS RecentCloseReason,
    R.LastPostDate,
    CASE 
        WHEN R.AvgScore IS NULL THEN 'No posts yet'
        ELSE CAST(R.AvgScore AS VARCHAR(255)) 
    END AS AverageScore
FROM UserReputation UR
LEFT JOIN RecentPostStats R ON UR.UserId = R.OwnerUserId
LEFT JOIN ClosedPosts CP ON R.OwnerUserId = CP.UserId
WHERE UR.Reputation >= (SELECT AVG(Reputation) FROM Users) 
ORDER BY UR.Reputation DESC, R.TotalPosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
