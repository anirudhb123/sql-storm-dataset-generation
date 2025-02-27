WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        ReputationRank
    FROM RankedUsers
    WHERE ReputationRank <= 10
),
UserBadges AS (
    SELECT 
        UB.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM Badges UB
    JOIN Users U ON UB.UserId = U.Id
    JOIN PostHistory PH ON U.Id = PH.UserId
    LEFT JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE U.Id IN (SELECT UserId FROM TopUsers)
    GROUP BY UB.UserId
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    UB.BadgeCount,
    UB.Badges
FROM TopUsers TU
LEFT JOIN UserBadges UB ON TU.UserId = UB.UserId
ORDER BY TU.Reputation DESC;
