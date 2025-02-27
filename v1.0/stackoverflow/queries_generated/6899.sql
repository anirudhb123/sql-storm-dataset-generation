WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId IN (2, 8) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN PostHistory ph ON u.Id = ph.UserId
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        us.UserId, 
        us.DisplayName, 
        us.Upvotes, 
        us.Downvotes, 
        us.PostCount,
        us.CommentCount, 
        us.BadgeCount, 
        us.HistoryCount
    FROM UserStats us
    WHERE us.PostCount > 10
    ORDER BY us.Upvotes DESC
    LIMIT 10
),
TopPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title,
        ps.CreationDate, 
        ps.Score, 
        ps.ViewCount,
        ps.CommentCount,
        ps.Upvotes, 
        ps.Downvotes
    FROM PostStats ps
    WHERE ps.Score > 0
    ORDER BY ps.ViewCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Upvotes AS UserUpvotes,
    tu.Downvotes AS UserDownvotes,
    tp.Title AS TopPost,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tp.ViewCount AS PostViewCount
FROM TopUsers tu
JOIN TopPosts tp ON tp.Upvotes > 5
ORDER BY tu.UserId, tp.ViewCount DESC;
