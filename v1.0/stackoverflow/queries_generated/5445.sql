WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COALESCE(SUM(c.Score), 0) AS CommentScores,
        COALESCE(SUM(v.BountyAmount), 0) AS BountySum,
        COALESCE(BR.BadgeCount, 0) AS BadgeTotal
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount
        FROM Badges
        GROUP BY UserId
    ) BR ON u.Id = BR.UserId
    GROUP BY u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, pt.Name
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.CommentScores,
        ua.BountySum,
        ROW_NUMBER() OVER (ORDER BY ua.PostCount DESC, ua.CommentScores DESC) AS Rank
    FROM UserActivity ua
    WHERE ua.PostCount > 0
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.PostCount,
    tu.CommentScores,
    tu.BountySum,
    ps.Title,
    ps.PostType,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.CreationDate
FROM TopUsers tu
JOIN PostStats ps ON ps.VoteCount > 10
WHERE tu.Rank <= 10
ORDER BY tu.Rank, ps.Score DESC;
