WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        QuestionCount, 
        AnswerCount,
        RANK() OVER (ORDER BY PostCount DESC) AS UserRank
    FROM 
        UserReputation
),
TopTags AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS UsageCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        B.Name AS BadgeName,
        B.Class,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Users U
    JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, B.Name, B.Class
),
UserBadgeStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN B.BadgeCount ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN B.BadgeCount ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN B.BadgeCount ELSE 0 END) AS BronzeBadges
    FROM 
        UserBadges U
    GROUP BY 
        U.UserId, U.DisplayName
)
SELECT 
    A.UserRank,
    A.DisplayName,
    A.Reputation,
    A.PostCount,
    A.QuestionCount,
    A.AnswerCount,
    COALESCE(B.GoldBadges, 0) AS GoldBadges,
    COALESCE(B.SilverBadges, 0) AS SilverBadges,
    COALESCE(B.BronzeBadges, 0) AS BronzeBadges,
    T.TagName,
    T.UsageCount
FROM 
    MostActiveUsers A
CROSS JOIN 
    TopTags T
LEFT JOIN 
    UserBadgeStats B ON A.UserId = B.UserId
WHERE 
    A.UserRank <= 10
ORDER BY 
    A.UserRank, T.UsageCount DESC;
