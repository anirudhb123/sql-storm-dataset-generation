-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        AVG(DATEDIFF(SECOND, p.CreationDate, p.LastActivityDate)) AS AvgResponseTime
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.AvgResponseTime,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalUpVotes,
    us.TotalDownVotes
FROM PostStats ps
JOIN UserStats us ON ps.OwnerUserId = us.UserId
ORDER BY ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
