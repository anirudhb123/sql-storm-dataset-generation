-- Performance benchmarking query
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COALESCE(SUM(vt.UserVoteCount), 0) AS TotalVotes,
        COALESCE(SUM(b.Id), 0) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS UserVoteCount
        FROM Votes
        GROUP BY UserId
    ) vt ON u.Id = vt.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.Reputation, u.CreationDate, u.LastAccessDate
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
    ORDER BY 
        p.Score DESC, p.ViewCount DESC
    LIMIT 10
)

SELECT 
    us.UserId,
    us.Reputation,
    us.TotalVotes,
    us.BadgeCount,
    us.TotalPosts,
    us.TotalComments,
    pp.PostId,
    pp.Title,
    pp.Score,
    pp.ViewCount,
    pp.CommentCount,
    pp.VoteCount
FROM 
    UserStats us
JOIN 
    PopularPosts pp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = pp.PostId)
ORDER BY 
    us.Reputation DESC, pp.Score DESC;
