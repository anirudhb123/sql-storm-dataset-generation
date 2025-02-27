WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
UserActivity AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        COALESCE(PS.TotalPosts, 0) AS PostCount,
        COALESCE(PS.Questions, 0) AS QuestionCount,
        COALESCE(PS.Answers, 0) AS AnswerCount,
        COALESCE(UBS.TotalBadges, 0) AS BadgeCount,
        COALESCE(UBS.GoldBadges, 0) AS GoldBadges,
        COALESCE(UBS.SilverBadges, 0) AS SilverBadges,
        COALESCE(UBS.BronzeBadges, 0) AS BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    LEFT JOIN UserBadgeStats UBS ON U.Id = UBS.UserId
)
SELECT 
    UA.DisplayName,
    UA.Reputation,
    UA.LastAccessDate,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.BadgeCount,
    UA.GoldBadges,
    UA.SilverBadges,
    UA.BronzeBadges,
    CASE 
        WHEN UA.Reputation > 1000 AND UA.BadgeCount > 0 THEN 'Active Contributor'
        WHEN UA.Reputation <= 1000 AND UA.BadgeCount = 0 THEN 'New User'
        ELSE 'Intermediate User'
    END AS UserType
FROM UserActivity UA
WHERE UA.PostCount > 5
  AND UA.LastAccessDate >= NOW() - INTERVAL '6 months'
ORDER BY UA.Reputation DESC
LIMIT 10
UNION ALL
SELECT 
    'Total' AS DisplayName,
    SUM(UA.Reputation) AS Reputation,
    NULL AS LastAccessDate,
    SUM(UA.PostCount) AS PostCount,
    SUM(UA.QuestionCount) AS QuestionCount,
    SUM(UA.AnswerCount) AS AnswerCount,
    SUM(UA.BadgeCount) AS BadgeCount,
    SUM(UA.GoldBadges) AS GoldBadges,
    SUM(UA.SilverBadges) AS SilverBadges,
    SUM(UA.BronzeBadges) AS BronzeBadges,
    'Summarized Data' AS UserType
FROM UserActivity UA;
