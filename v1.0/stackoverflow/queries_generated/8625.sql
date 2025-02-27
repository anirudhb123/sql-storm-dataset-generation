WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - u.CreationDate)) / (60 * 60 * 24)) AS AvgAccountAgeDays
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        AvgAccountAgeDays
    FROM UserActivity
    WHERE PostCount > 0
    ORDER BY PostCount DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.CommentCount,
    tu.UpVoteCount,
    tu.DownVoteCount,
    ub.BadgeCount,
    ub.GoldBadgeCount,
    ub.SilverBadgeCount,
    ub.BronzeBadgeCount,
    tu.AvgAccountAgeDays
FROM TopUsers tu
LEFT JOIN UserBadges ub ON tu.UserId = ub.UserId
ORDER BY tu.PostCount DESC;
