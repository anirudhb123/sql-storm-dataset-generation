WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(u.Reputation) AS TotalReputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.TotalBounty,
    us.UserId,
    us.PostCount,
    us.TotalReputation,
    us.BadgeCount
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
