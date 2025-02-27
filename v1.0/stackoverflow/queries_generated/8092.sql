WITH UserScore AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(POSTS.ViewCount) AS TotalViews,
        SUM(COALESCE(POSTS.Score, 0)) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
), 
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        Score * 1.0 / NULLIF((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS ScorePerUpvote
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    us.UserId,
    us.BadgeCount,
    us.Upvotes,
    us.Downvotes,
    us.TotalViews,
    us.TotalScore,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.ScorePerUpvote
FROM 
    UserScore us
JOIN 
    PostStatistics ps ON us.UserId = ps.OwnerUserId
ORDER BY 
    us.TotalScore DESC, us.BadgeCount DESC
LIMIT 100;
