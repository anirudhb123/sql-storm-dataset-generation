WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS TotalComments
    FROM 
        Comments
    GROUP BY 
        PostId
),
BadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
ClosedPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        ph.CreationDate AS ClosedDate,
        ph.UserDisplayName AS ClosedBy
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    cc.TotalComments,
    bc.BadgeCount,
    cp.ClosedDate,
    cp.ClosedBy
FROM 
    RankedPosts rp
LEFT JOIN 
    CommentCounts cc ON rp.Id = cc.PostId
LEFT JOIN 
    BadgeCounts bc ON rp.OwnerUserId = bc.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.Id = cp.Id
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC
LIMIT 10;
