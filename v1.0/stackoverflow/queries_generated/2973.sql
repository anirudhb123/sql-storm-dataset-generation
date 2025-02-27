WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.Score > 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    ub.BadgeCount,
    ub.BadgeNames,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    rp.UpVoteCount,
    rp.DownVoteCount
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;

-- Additional aggregate statistics
WITH PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.DisplayName,
    ps.TotalPosts,
    COALESCE(ps.TotalBounty, 0) AS TotalBounty,
    COALESCE(ps.AverageScore, 0) AS AverageScore
FROM 
    Users u
LEFT JOIN 
    PostStats ps ON u.Id = ps.OwnerUserId
WHERE 
    ps.TotalPosts IS NOT NULL
ORDER BY 
    ps.TotalPosts DESC
LIMIT 10;
