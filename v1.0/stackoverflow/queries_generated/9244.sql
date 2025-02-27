WITH UserStatistics AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(c.Score), 0) AS CommentScore,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        CommentScore,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStatistics
)
SELECT 
    t.DisplayName,
    t.Reputation,
    t.PostCount,
    t.QuestionCount,
    t.AnswerCount,
    t.UpVotes,
    t.DownVotes,
    t.CommentScore,
    t.GoldBadges,
    t.SilverBadges,
    t.BronzeBadges
FROM TopUsers t
WHERE t.ReputationRank <= 10
ORDER BY t.Reputation DESC, t.PostCount DESC;
