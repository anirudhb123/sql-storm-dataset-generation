WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.Score, 0)) AS TotalVotes,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(LENGTH(p.Body)) AS AvgPostLength
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
), UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
), CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalComments,
        ups.TotalVotes,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.AvgPostLength,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM UserPostStats ups
    LEFT JOIN UserBadges ub ON ups.UserId = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    QuestionCount,
    AnswerCount,
    AvgPostLength,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM CombinedStats
ORDER BY TotalVotes DESC, TotalPosts DESC
LIMIT 10;
