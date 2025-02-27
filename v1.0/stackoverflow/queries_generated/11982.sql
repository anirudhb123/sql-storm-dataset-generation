-- Performance Benchmarking Query

WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes,
        SUM(v.VoteTypeId = 3) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalBadges,
    us.TotalUpVotes,
    us.TotalDownVotes,
    ps.PostId,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.ViewCount,
    ps.Score AS PostScore,
    ps.CommentCount
FROM UserStatistics us
JOIN PostStatistics ps ON us.UserId = ps.PostId
ORDER BY us.Reputation DESC, ps.Score DESC
LIMIT 100; -- Limiting to the top 100 for performance benchmarking
