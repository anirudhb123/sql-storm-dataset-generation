-- Performance Benchmarking SQL Query

WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(VCASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(VCASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.LastActivityDate,
    ps.Upvotes,
    ps.Downvotes,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.TotalBounty
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.ViewCount DESC
LIMIT 100;
