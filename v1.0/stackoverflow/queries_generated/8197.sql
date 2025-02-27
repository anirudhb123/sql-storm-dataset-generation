WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        QuestionCount,
        UpVotes,
        DownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        TotalViews,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStatistics
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.AnswerCount,
    u.QuestionCount,
    u.UpVotes,
    u.DownVotes,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.TotalViews
FROM TopUsers u
WHERE u.ReputationRank <= 10
ORDER BY u.Reputation DESC;
