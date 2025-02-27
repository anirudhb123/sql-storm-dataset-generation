-- Performance Benchmarking SQL Query

-- This query retrieves user statistics, post statistics, and badges awarded to the users,
-- helping to understand the correlation between user activity and post engagement.

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY u.Id, u.Reputation
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(DISTINCT Id) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
)

SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges
FROM UserStats us
LEFT JOIN BadgeStats bs ON us.UserId = bs.UserId
ORDER BY us.Reputation DESC, us.PostCount DESC;
