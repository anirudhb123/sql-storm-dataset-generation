WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COALESCE(SUBSTRING(p.Tags FROM '(^|,)([^,]*)(,|$)')::text[], '{}') AS TagArray
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COALESCE(SUM(v.UserId IS NOT NULL AND v.VoteTypeId = 2), 0) AS Upvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN (SELECT Name FROM CloseReasonTypes WHERE Id = ph.Comment::int)
            ELSE NULL 
        END AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
),
FinalPostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        up.PostCount,
        up.CommentCount,
        up.BadgeCount,
        up.TotalBounty,
        up.Upvotes,
        PHD.CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserPostStatistics up ON rp.OwnerUserId = up.UserId
    LEFT JOIN 
        PostHistoryDetails PHD ON rp.PostId = PHD.PostId
    WHERE 
        rp.Rank <= 5
)

SELECT 
    fpm.PostId,
    fpm.Title,
    fpm.CreationDate,
    fpm.OwnerUserId,
    fpm.PostCount,
    fpm.CommentCount,
    fpm.BadgeCount,
    fpm.TotalBounty,
    fpm.Upvotes,
    COALESCE(fpm.CloseReason, 'Not Applicable') AS CloseReasonStatus
FROM 
    FinalPostMetrics fpm
ORDER BY 
    fpm.Score DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY
;
