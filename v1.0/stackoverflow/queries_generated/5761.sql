WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(b.Class) AS BadgeScore, 
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation + COALESCE(BadgeScore, 0) AS TotalScore,
        PostCount,
        CommentCount
    FROM UserReputation
    WHERE Reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.TotalScore,
    tu.PostCount,
    tu.CommentCount,
    pt.Name AS PostTypeName,
    COUNT(v.Id) AS VoteCount
FROM TopUsers tu
JOIN Posts p ON tu.UserId = p.OwnerUserId
JOIN PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY tu.UserId, tu.DisplayName, tu.TotalScore, tu.PostCount, tu.CommentCount, pt.Name
HAVING COUNT(v.Id) > 5
ORDER BY TotalScore DESC, PostCount DESC
LIMIT 10;
