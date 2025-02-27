-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(MAX(p.LastEditDate), p.CreationDate) AS LastModifiedDate,
        COALESCE(MAX(ph.CreationDate), p.CreationDate) AS LastHistoryDate
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
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ps.BadgeCount,
    ps.LastModifiedDate,
    ps.LastHistoryDate,
    us.UserId,
    us.DisplayName,
    us.TotalBounty,
    us.AvgReputation,
    us.TotalBadges
FROM 
    PostStats ps
JOIN 
    Users us ON ps.PostId = us.Id
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
