
WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount, MAX(Date) AS LastBadgeDate
    FROM Badges
    GROUP BY UserId
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ISNULL(c.CommentCount, 0) AS CommentCount,
        ISNULL(a.AnswerCount, 0) AS AnswerCount,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ISNULL(ub.BadgeCount, 0) AS BadgeCount,
        ISNULL(SUM(p.Score), 0) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN UserBadgeCount ub ON u.Id = ub.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, ub.BadgeCount
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.BadgeCount,
    tu.TotalScore,
    tu.PostCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.RankScore
FROM TopUsers tu
JOIN PostStatistics ps ON tu.PostCount > 0
ORDER BY tu.TotalScore DESC, ps.RankScore ASC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
