-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    ps.PostId,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount,
    ps.BadgeCount AS PostOwnerBadgeCount,
    us.UserId,
    us.Reputation,
    us.TotalBountyAmount,
    us.PostCount,
    us.BadgeCount AS UserBadgeCount
FROM 
    PostStats ps
JOIN 
    Users u ON ps.PostId = u.Id -- Adjusting to join proper User representation
JOIN 
    UserStats us ON u.Id = us.UserId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
