WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
RecentClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
        AND ph.CreationDate > NOW() - INTERVAL '30 days'
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    rp.PostId,
    rp.Title,
    rp.ViewCount AS RecentViewCount,
    rp.Score AS RecentScore,
    us.TotalBounties,
    us.TotalBadges,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(rcp.Comment, 'No recent closure reason') AS ClosureReason
FROM 
    UserStatistics us
JOIN 
    RankedPosts rp ON rp.rn = 1
JOIN 
    RecentClosedPosts rcp ON rp.PostId = rcp.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
JOIN 
    Users up ON up.Id = rp.OwnerUserId
WHERE 
    us.TotalBadges > 3 
    AND rp.ViewCount > 100
ORDER BY 
    us.TotalBounties DESC, 
    rp.Score DESC;
