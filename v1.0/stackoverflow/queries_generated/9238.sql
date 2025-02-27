WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(p.Score) AS AverageScore,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        AverageScore,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY PostCount DESC) AS ActivityRank
    FROM UserActivity
)
SELECT 
    u.DisplayName,
    u.PostCount AS TotalPosts,
    u.QuestionCount,
    u.AnswerCount,
    u.AverageScore,
    u.UpVotes,
    u.DownVotes,
    (u.GoldBadges + u.SilverBadges + u.BronzeBadges) AS TotalBadges,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges
FROM TopActiveUsers u
WHERE u.ActivityRank <= 10
ORDER BY u.PostCount DESC;
