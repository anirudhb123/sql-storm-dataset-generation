WITH UserBadges AS (
    SELECT UserId, COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
                  COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
                  COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
UserStats AS (
    SELECT u.Id AS UserId, u.DisplayName, u.Reputation, 
           COALESCE(ub.GoldBadges, 0) AS GoldBadges, 
           COALESCE(ub.SilverBadges, 0) AS SilverBadges, 
           COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
           COUNT(DISTINCT p.Id) AS PostCount,
           SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
           SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT UserId, DisplayName, Reputation, GoldBadges, SilverBadges, BronzeBadges,
           PostCount, QuestionCount, AnswerCount,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT UserId, DisplayName, Reputation, GoldBadges, SilverBadges, BronzeBadges,
       PostCount, QuestionCount, AnswerCount, ReputationRank
FROM TopUsers
WHERE ReputationRank <= 10
ORDER BY Reputation DESC;
