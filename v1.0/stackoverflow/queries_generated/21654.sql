WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(COALESCE(v.BountyAmount, 0)) OVER (PARTITION BY p.OwnerUserId) AS TotalBounty,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.OwnerUserId) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- BountyStart and BountyClose
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostWithBadges AS (
    SELECT 
        rp.PostId,
        u.Id AS UserId,
        u.DisplayName,
        CASE 
            WHEN b.Class = 1 THEN 'Gold'
            WHEN b.Class = 2 THEN 'Silver'
            WHEN b.Class = 3 THEN 'Bronze'
            ELSE 'No Badge'
        END AS BadgeType,
        rp.TotalBounty,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Date >= rp.CreationDate
    WHERE 
        rp.rn = 1
)
SELECT 
    pwb.PostId,
    pwb.DisplayName,
    pwb.BadgeType,
    pwb.TotalBounty,
    pwb.CommentCount,
    COALESCE(reasons.ReasonText, 'No close reason') AS CloseReason,
    COALESCE(SUM(case when phh.PostHistoryTypeId = 10 then 1 else 0 end), 0) AS CloseCount
FROM 
    PostWithBadges pwb
LEFT JOIN (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS ReasonText
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 OR ph.PostHistoryTypeId = 11  -- post closed or reopened
    GROUP BY 
        ph.PostId
) reasons ON pwb.PostId = reasons.PostId
LEFT JOIN 
    PostHistory phh ON pwb.PostId = phh.PostId
GROUP BY 
    pwb.PostId, pwb.DisplayName, pwb.BadgeType, pwb.TotalBounty, pwb.CommentCount, reasons.ReasonText
ORDER BY 
    pwb.TotalBounty DESC, pwb.CommentCount DESC, pwb.DisplayName;

