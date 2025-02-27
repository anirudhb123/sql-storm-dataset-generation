-- Performance benchmarking query for Stack Overflow schema

WITH MostActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
    ORDER BY PostCount DESC
    LIMIT 10
),

TopPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS Author
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    ORDER BY p.Score DESC
    LIMIT 5
),

UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    a.UserId,
    a.DisplayName,
    a.PostCount,
    a.TotalBounty,
    b.BadgeCount,
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount
FROM MostActiveUsers a
LEFT JOIN UserBadges b ON a.UserId = b.UserId
LEFT JOIN TopPosts p ON a.UserId = p.Author
ORDER BY a.PostCount DESC, b.BadgeCount DESC;
