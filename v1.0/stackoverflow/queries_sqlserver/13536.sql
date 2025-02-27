
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
        AVG(ISNULL(P.ViewCount, 0)) AS AvgViewCount,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.PostCount,
    UPS.QuestionCount,
    UPS.AnswerCount,
    UPS.TotalScore,
    UPS.AvgViewCount,
    UPS.LastPostDate,
    ISNULL(UBS.BadgeCount, 0) AS BadgeCount,
    ISNULL(UBS.GoldBadgeCount, 0) AS GoldBadgeCount,
    ISNULL(UBS.SilverBadgeCount, 0) AS SilverBadgeCount,
    ISNULL(UBS.BronzeBadgeCount, 0) AS BronzeBadgeCount
FROM 
    UserPostStats UPS
LEFT JOIN 
    UserBadgeStats UBS ON UPS.UserId = UBS.UserId
ORDER BY 
    UPS.TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
