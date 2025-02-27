WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        U.DisplayName,
        PH.CreationDate,
        PH.Comment AS CloseReason
    FROM PostHistory PH
    JOIN Users U ON PH.UserId = U.Id
    WHERE PH.PostHistoryTypeId = 10
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(*) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    COALESCE(PS.QuestionCount, 0) AS QuestionCount,
    COALESCE(PS.AnswerCount, 0) AS AnswerCount,
    COALESCE(PS.TotalScore, 0) AS TotalScore,
    COALESCE(PS.AverageViewCount, 0) AS AverageViewCount,
    COALESCE(CP.CloseReason, 'None') AS LastCloseReason,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN UB.HighestBadgeClass = 1 THEN 'Gold'
        WHEN UB.HighestBadgeClass = 2 THEN 'Silver'
        WHEN UB.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS HighestBadge
FROM UserReputation UR
LEFT JOIN PostStats PS ON UR.UserId = PS.OwnerUserId
LEFT JOIN ClosedPosts CP ON UR.UserId = CP.DisplayName
LEFT JOIN UserBadges UB ON UR.UserId = UB.UserId
WHERE UR.Reputation > 1000
ORDER BY UR.Reputation DESC, UR.DisplayName
LIMIT 10;
