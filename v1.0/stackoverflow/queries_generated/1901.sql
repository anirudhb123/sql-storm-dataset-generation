WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT pp.Id) AS PostsCreated
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts pp ON u.Id = pp.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
        AND ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
)
SELECT 
    u.DisplayName,
    us.TotalBounties,
    us.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(cp.Comment, 'No recent closures') AS RecentClosureStatus,
    rp.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Recent Post'
        ELSE 'Other Posts'
    END AS PostStatus
FROM 
    UserScores us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
LEFT OUTER JOIN 
    ClosedPosts cp ON rp.Id = cp.PostId
WHERE 
    rp.PostRank <= 5 
ORDER BY 
    us.TotalBounties DESC, 
    rp.Score DESC;
