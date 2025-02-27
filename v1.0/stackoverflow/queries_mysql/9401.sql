
WITH UserStats AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN Posts.Score ELSE 0 END) AS TotalScore,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN Posts.PostTypeId = 2 THEN Posts.Id END) AS TotalAnswers,
        COUNT(DISTINCT CASE WHEN Posts.PostTypeId = 1 THEN Posts.Id END) AS TotalQuestions
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id, Users.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalScore,
        TotalPosts,
        TotalQuestions,
        @rank := IF(@prev_score = TotalScore, @rank, @rank + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM UserStats, (SELECT @rank := 0, @prev_score := NULL) AS vars
    ORDER BY TotalScore DESC
),
TotalBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)
SELECT 
    TopUsers.UserId,
    TopUsers.DisplayName,
    TopUsers.TotalScore,
    TopUsers.TotalPosts,
    TopUsers.TotalQuestions,
    TotalBadges.BadgeCount,
    TotalBadges.GoldBadges,
    TotalBadges.SilverBadges,
    TotalBadges.BronzeBadges,
    TopUsers.ScoreRank
FROM TopUsers
LEFT JOIN TotalBadges ON TopUsers.UserId = TotalBadges.UserId
WHERE TopUsers.ScoreRank <= 10
ORDER BY TopUsers.ScoreRank;
