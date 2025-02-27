WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(*) AS TotalPosts, 
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        c.PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    WHERE 
        c.CreationDate >= NOW() - INTERVAL '15 days'
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    us.DisplayName AS UserDisplayName, 
    us.TotalPosts, 
    us.TotalBounties, 
    COALESCE(rc.CommentCount, 0) AS RecentCommentCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RecentComments rc ON rp.PostId = rc.PostId
WHERE 
    rp.PostRank <= 5 -- Top 5 posts per type
ORDER BY 
    rp.PostTypeId, rp.Score DESC;

-- This query fetches the top posts for each post type in the last 30 days, along with user stats and recent comment counts.
