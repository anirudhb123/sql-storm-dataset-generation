WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        COALESCE(c.Description, 'No reason provided') AS Reason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        COALESCE(u.Reputation, 0) AS Reputation,
        SUM(CASE WHEN bp.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts bp ON u.Id = bp.OwnerUserId
    WHERE 
        u.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(bp.Id) > 5
),
FinalResults AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        us.TotalBounty,
        us.BadgeCount,
        tp.Reputation,
        tp.PositivePosts,
        rp.PostId,
        rp.Title,
        rp.CreationDate AS PostCreationDate,
        rp.Score,
        rp.ViewCount,
        cpd.Reason AS CloseReason
    FROM 
        UserStats us
    JOIN 
        TopUsers tp ON us.UserId = tp.UserId
    LEFT JOIN 
        RankedPosts rp ON us.UserId = rp.OwnerUserId AND rp.rn = 1
    LEFT JOIN 
        ClosedPostDetails cpd ON rp.PostId = cpd.PostId
)
SELECT 
    *,
    CASE 
        WHEN CloseReason IS NOT NULL THEN 'Closed Post'
        ELSE 'Active Post'
    END AS PostStatus,
    CASE 
        WHEN TotalBounty IS NULL THEN 'No Bounty'
        ELSE TotalBounty::text || ' Points'
    END AS BountyStatus
FROM 
    FinalResults
ORDER BY 
    Reputation DESC, TotalBounty DESC, PostCreationDate DESC
LIMIT 50;
