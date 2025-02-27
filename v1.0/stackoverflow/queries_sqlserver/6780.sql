
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName, pt.Name
    ORDER BY p.CreationDate DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
TopUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.PostCount,
        ua.PositivePosts,
        (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = ua.UserId) AS BadgeCount
    FROM UserActivity ua
    WHERE ua.PostCount > 0
    ORDER BY ua.PositivePosts DESC, ua.PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.PostCount,
    tu.PositivePosts,
    tu.BadgeCount,
    rp.Title AS RecentPostTitle,
    rp.Author AS RecentPostAuthor,
    rp.CreationDate AS RecentPostDate,
    rp.CommentCount AS RecentPostComments
FROM TopUsers tu
JOIN RecentPosts rp ON tu.DisplayName = rp.Author
ORDER BY tu.PositivePosts DESC, rp.CreationDate DESC;
