WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(c.CloseReason, 'Not Closed') AS CloseReason,
        rs.TotalBounty,
        us.BadgeCount,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPosts c ON p.Id = c.PostId
    LEFT JOIN 
        UserStats us ON p.OwnerUserId = us.UserId
    LEFT JOIN 
        RankedPosts rs ON p.Id = rs.PostId
    WHERE 
        p.ViewCount > 1000 -- Only posts with a significant view count
)
SELECT 
    pd.Title,
    pd.CloseReason,
    pd.TotalBounty,
    pd.BadgeCount,
    pd.RecentRank
FROM 
    PostDetails pd
WHERE 
    pd.RecentRank <= 10 -- Limit to top 10 recent posts
ORDER BY 
    pd.TotalBounty DESC, pd.BadgeCount DESC;
