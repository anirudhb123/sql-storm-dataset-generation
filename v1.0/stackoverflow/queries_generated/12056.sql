-- Performance Benchmarking Query
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEditDate,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostsCreated,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CommentCount,
    ps.VoteCount,
    ps.LastEditDate,
    ps.TotalBounty,
    ua.UserId,
    ua.DisplayName AS PostOwner,
    ua.PostsCreated,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges
FROM 
    PostSummary ps
JOIN 
    UserActivity ua ON ps.PostId = ua.UserId
ORDER BY 
    ps.TotalBounty DESC, ps.CommentCount DESC;
