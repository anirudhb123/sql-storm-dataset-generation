WITH UserBadgeSummary AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
CombinedMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(PS.TotalScore, 0) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        UserBadgeSummary UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostSummary PS ON U.Id = PS.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    BadgeCount,
    PostCount,
    TotalScore,
    QuestionCount,
    AnswerCount,
    Rank
FROM 
    CombinedMetrics
WHERE 
    BadgeCount > 0 OR PostCount > 0
ORDER BY 
    Rank
LIMIT 50;

-- OPTIONAL: To include posts that are not deleted
SELECT 
    RU.UserId,
    RU.DisplayName,
    COALESCE(PS.PostCount, 0) AS ActivePostCount,
    SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts
FROM 
    CombinedMetrics RU
LEFT JOIN 
    Posts PS ON RU.UserId = PS.OwnerUserId AND PS.Deleted = FALSE
LEFT JOIN 
    PostHistory PH ON PS.Id = PH.PostId
WHERE 
    RU.Rank <= 50
GROUP BY 
    RU.UserId, RU.DisplayName
ORDER BY 
    ActivePostCount DESC;
