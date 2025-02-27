-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT bh.Id) AS EditCount,
        MAX(bh.CreationDate) AS LastEditDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory bh ON p.Id = bh.PostId
    GROUP BY p.Id, p.Title
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.EditCount,
    ps.LastEditDate,
    us.UserId,
    us.DisplayName,
    us.TotalViews,
    us.AvgReputation,
    us.PostsCount
FROM PostStats ps
JOIN UserStats us ON ps.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
ORDER BY ps.UpVoteCount DESC, ps.CommentCount DESC;
