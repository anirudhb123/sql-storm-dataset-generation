
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
RecentPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AverageScore,
        GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') AS TagsUsed
    FROM Posts P
    JOIN (
        SELECT 
            P.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) AS TagName
        FROM 
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
        INNER JOIN Posts P ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    ) T ON P.Id = T.Id
    WHERE P.LastActivityDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.OwnerUserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.ReputationRank,
    COALESCE(RP.TotalPosts, 0) AS TotalPosts,
    COALESCE(RP.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(RP.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(RP.AverageScore, 0) AS AverageScore,
    COALESCE(RB.GoldBadges, 0) AS GoldBadges,
    COALESCE(RB.SilverBadges, 0) AS SilverBadges,
    COALESCE(RB.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(RP.TagsUsed, 'No Tags') AS TagsUsed
FROM UserReputation UR
LEFT JOIN RecentPostStats RP ON UR.UserId = RP.OwnerUserId
LEFT JOIN UserBadges RB ON UR.UserId = RB.UserId
WHERE UR.ReputationRank <= 50
ORDER BY UR.Reputation DESC;
