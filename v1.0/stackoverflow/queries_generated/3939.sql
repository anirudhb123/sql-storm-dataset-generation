WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) FILTER (WHERE c.PostId IS NOT NULL) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalBounties,
    us.TotalPosts,
    us.TotalComments,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    ps.Rank
FROM UserStats us
LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
WHERE us.Reputation > 1000
  AND (ps.Rank <= 5 OR ps.Rank IS NULL)
ORDER BY us.Reputation DESC, ps.Score DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
