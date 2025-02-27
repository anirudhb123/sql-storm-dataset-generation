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
TopPosters AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(Id) > 10
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        TP.PostCount,
        TP.QuestionCount,
        TP.AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        TopPosters TP ON U.Id = TP.OwnerUserId
)
SELECT 
    UserId,
    DisplayName,
    COALESCE(BadgeCount, 0) AS BadgeCount,
    COALESCE(PostCount, 0) AS PostCount,
    COALESCE(QuestionCount, 0) AS QuestionCount,
    COALESCE(AnswerCount, 0) AS AnswerCount,
    U.Reputation,
    U.CreationDate,
    U.LastAccessDate,
    U.Location
FROM 
    UserPostStats U
ORDER BY 
    BadgeCount DESC, PostCount DESC
LIMIT 50;
