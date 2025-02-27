WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        CreationDate,
        PostCount,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY Reputation DESC, PostCount DESC) AS UserRank
    FROM UserStats
)
SELECT 
    tu.DisplayName, 
    tu.Reputation, 
    tu.PostCount, 
    tu.GoldBadges, 
    tu.SilverBadges, 
    tu.BronzeBadges, 
    tu.UpVotes, 
    tu.DownVotes
FROM TopUsers tu
WHERE tu.UserRank <= 10
ORDER BY tu.Reputation DESC, tu.PostCount DESC;
