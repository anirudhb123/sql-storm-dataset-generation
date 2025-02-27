WITH RankedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
),
UserBadges AS (
    SELECT u.Id AS UserId, COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostTypesCount AS (
    SELECT pt.Name AS PostType, COUNT(p.Id) AS TotalPosts
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY pt.Name
    ORDER BY TotalPosts DESC
),
TopUsers AS (
    SELECT u.DisplayName, u.Reputation, ub.BadgeCount
    FROM Users u
    JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE u.Reputation > 1000
    ORDER BY u.Reputation DESC 
    LIMIT 10
)
SELECT rp.Title, rp.CreationDate, rp.Score, rp.CommentCount, pu.DisplayName, pu.Reputation, pu.BadgeCount, ptc.PostType, ptc.TotalPosts
FROM RankedPosts rp
JOIN TopUsers pu ON pu.UserId = rp.Id
JOIN PostTypesCount ptc ON TRUE
WHERE rp.RN = 1
ORDER BY rp.Score DESC, rp.CommentCount DESC;
