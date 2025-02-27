
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(IFNULL(P.Score, 0)) AS TotalScore,
        SUM(IFNULL(P.AnswerCount, 0)) AS TotalAnswers,
        MAX(P.CreationDate) AS LastPostDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
BadgesSummary AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
HighlyActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalScore,
        UA.TotalAnswers,
        IFNULL(BG.GoldBadges, 0) AS GoldBadges,
        IFNULL(BS.SilverBadges, 0) AS SilverBadges,
        IFNULL(BR.BronzeBadges, 0) AS BronzeBadges,
        UA.LastPostDate
    FROM 
        UserActivity UA
    LEFT JOIN 
        BadgesSummary BG ON UA.UserId = BG.UserId
    LEFT JOIN 
        BadgesSummary BS ON UA.UserId = BS.UserId
    LEFT JOIN 
        BadgesSummary BR ON UA.UserId = BR.UserId
    WHERE 
        UA.TotalScore > 5000 OR UA.TotalAnswers > 20
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    TotalScore,
    TotalAnswers,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    LastPostDate
FROM 
    HighlyActiveUsers
WHERE 
    LastPostDate >= CURDATE() - INTERVAL 1 YEAR
ORDER BY 
    TotalScore DESC, PostCount DESC
LIMIT 10;
