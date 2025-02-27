WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
PostAggregates AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionsCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswersCount,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PHT.Name AS HistoryType,
        COUNT(PH.Id) AS HistoryCount
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        PH.PostId, PHT.Name
    HAVING 
        COUNT(PH.Id) > 2
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PA.PostCount, 0) AS PostCount,
        COALESCE(PA.QuestionsCount, 0) AS QuestionsCount,
        COALESCE(PA.AnswersCount, 0) AS AnswersCount,
        COALESCE(PA.AvgScore, 0) AS AvgScore,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount,
        COALESCE(UBC.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBC.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBC.BronzeBadges, 0) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        PostAggregates PA ON U.Id = PA.OwnerUserId
    LEFT JOIN 
        UserBadgeCounts UBC ON U.Id = UBC.UserId
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.QuestionsCount,
    U.AnswersCount,
    U.AvgScore,
    U.BadgeCount,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    PH.HistoryType,
    PH.HistoryCount
FROM 
    UserPerformance U
LEFT JOIN 
    PostHistoryDetails PH ON U.UserId IN (
        SELECT DISTINCT OwnerUserId
        FROM Posts
        WHERE Id IN (SELECT PostId FROM PostHistory)
    )
WHERE 
    U.PostCount > 5 -- Filter to only users with more than 5 posts
ORDER BY 
    U.AvgScore DESC, U.BadgeCount DESC, U.DisplayName ASC;
