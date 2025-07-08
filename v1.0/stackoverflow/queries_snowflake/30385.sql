
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) OVER (PARTITION BY p.Id) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) OVER (PARTITION BY p.Id) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01'::DATE)
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        p.OwnerDisplayName,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.LastActivityDate >= DATEADD(day, -30, '2024-10-01'::DATE)
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
)
SELECT 
    rp.PostId,
    rp.Title,
    us.DisplayName AS PostOwner,
    rp.ViewCount,
    rp.Score,
    rp.Upvotes,
    rp.Downvotes,
    us.BadgeCount,
    ra.CommentCount,
    cp.CloseReason,
    CASE 
        WHEN cp.CloseReason IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.PostId = us.UserId
LEFT JOIN 
    RecentActivity ra ON rp.PostId = ra.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
