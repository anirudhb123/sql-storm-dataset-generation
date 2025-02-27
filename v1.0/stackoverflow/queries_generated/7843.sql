WITH UserRankings AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) as ReputationScore,
        COUNT(DISTINCT p.Id) as PostCount,
        COUNT(DISTINCT c.Id) as CommentCount,
        COUNT(DISTINCT b.Id) as BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 0
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        ReputationScore, 
        PostCount, 
        CommentCount, 
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ReputationScore DESC, PostCount DESC) as Rank
    FROM UserRankings
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.ReputationScore,
    tu.PostCount,
    tu.CommentCount,
    tu.BadgeCount,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    STRING_AGG(DISTINCT lt.Name, ', ') AS LinkTypes
FROM TopUsers tu
LEFT JOIN Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN PostLinks pl ON p.Id = pl.PostId
LEFT JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
WHERE tu.Rank <= 10
GROUP BY tu.Rank, tu.DisplayName, tu.ReputationScore, tu.PostCount, tu.CommentCount, tu.BadgeCount
ORDER BY tu.Rank;
