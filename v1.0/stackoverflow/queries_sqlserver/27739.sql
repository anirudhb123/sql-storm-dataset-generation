
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U 
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P 
    GROUP BY 
        P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        B.BadgeCount,
        B.GoldBadges,
        B.SilverBadges,
        B.BronzeBadges,
        P.PostCount,
        P.QuestionCount,
        P.AnswerCount,
        P.TotalViews,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate
    FROM 
        Users U 
    JOIN 
        UserBadges B ON U.Id = B.UserId
    JOIN 
        UserPostStats P ON U.Id = P.OwnerUserId
)
SELECT TOP 10
    UA.DisplayName,
    UA.Reputation,
    UA.BadgeCount,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalViews,
    'User ' + UA.DisplayName + ' has earned ' + CAST(UA.BadgeCount AS NVARCHAR(10)) + ' badges (' + 
        CAST(UA.GoldBadges AS NVARCHAR(10)) + ' gold, ' + CAST(UA.SilverBadges AS NVARCHAR(10)) + ' silver, ' + CAST(UA.BronzeBadges AS NVARCHAR(10)) + ' bronze) and has created ' + 
        CAST(UA.PostCount AS NVARCHAR(10)) + ' posts (' + CAST(UA.QuestionCount AS NVARCHAR(10)) + ' questions and ' + CAST(UA.AnswerCount AS NVARCHAR(10)) + ' answers) with a total of ' + 
        CAST(UA.TotalViews AS NVARCHAR(10)) + ' views' AS UserSummary
FROM 
    UserActivity UA
ORDER BY 
    UA.Reputation DESC, UA.BadgeCount DESC;
