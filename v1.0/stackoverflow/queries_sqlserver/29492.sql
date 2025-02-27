
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
FinalStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(UB.GoldBadgeCount, 0) AS GoldBadgeCount,
        COALESCE(UB.SilverBadgeCount, 0) AS SilverBadgeCount,
        COALESCE(UB.BronzeBadgeCount, 0) AS BronzeBadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.AvgViewCount, 0) AS AvgViewCount
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
)
SELECT TOP 10
    UserId,
    DisplayName,
    BadgeCount,
    GoldBadgeCount,
    SilverBadgeCount,
    BronzeBadgeCount,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalScore,
    AvgViewCount,
    'User: ' + DisplayName + ' has ' + CAST(BadgeCount AS VARCHAR(10)) + ' badges. ' +
    'They have created ' + CAST(PostCount AS VARCHAR(10)) + ' posts (' + 
    CAST(QuestionCount AS VARCHAR(10)) + ' questions, ' +
    CAST(AnswerCount AS VARCHAR(10)) + ' answers). Their total score is: ' + 
    CAST(TotalScore AS VARCHAR(10)) + '. ' +
    'Average view count per post is: ' + CAST(ROUND(AvgViewCount, 2) AS VARCHAR(10)) AS UserSummary
FROM FinalStats
ORDER BY TotalScore DESC, BadgeCount DESC;
