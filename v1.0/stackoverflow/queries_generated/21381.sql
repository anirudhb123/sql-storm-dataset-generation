WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(NULLIF(SUM(v.BountyAmount), 0), 0) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8  -- Counting BountyStart votes
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS ChangeCount,
        MAX(ph.CreationDate) AS LastChangeDate,
        STRING_AGG(DISTINCT ph.UserDisplayName, ', ') AS Editors
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
CloseReasonSummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END) AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    ur.Reputation,
    ur.TotalBounty,
    ur.BadgeCount,
    ph.ChangeCount,
    ph.LastChangeDate,
    ph.Editors,
    cr.CloseReason
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId AND ph.ChangeCount > 0
LEFT JOIN 
    CloseReasonSummary cr ON rp.PostId = cr.PostId
WHERE 
    rp.rn = 1  -- Only the top post per user
    AND ur.Reputation > 100  -- Filter for users with high reputation
ORDER BY 
    rp.Score DESC, 
    ur.BadgeCount DESC
LIMIT 100;

-- Consideration of NULL handling: The presence of LEFT JOINs ensures we capture users or posts even if they lack certain history or reputation metrics.
