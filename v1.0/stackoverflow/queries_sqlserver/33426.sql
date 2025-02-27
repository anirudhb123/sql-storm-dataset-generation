
WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews
    FROM Posts P
    WHERE P.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        B.BadgeCount,
        R.TotalPosts,
        R.Questions,
        R.Answers,
        R.TotalScore,
        R.AvgViews,
        R.OwnerUserId
    FROM Users U
    JOIN UserBadgeCounts B ON U.Id = B.UserId
    JOIN RecentPostStats R ON U.Id = R.OwnerUserId
    ORDER BY U.Reputation DESC
)
SELECT TOP 10
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    R.TotalPosts,
    R.Questions,
    R.Answers,
    R.TotalScore,
    R.AvgViews
FROM TopUsers U
JOIN RecentPostStats R ON U.Id = R.OwnerUserId
LEFT JOIN PostHistory PH ON PH.UserId = U.Id AND PH.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
WHERE R.TotalPosts > 0
ORDER BY U.BadgeCount DESC, R.TotalScore DESC;
