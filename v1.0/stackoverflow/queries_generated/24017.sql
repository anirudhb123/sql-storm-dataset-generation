WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(vb.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes vb ON p.Id = vb.PostId AND vb.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    WHERE 
        p.PostTypeId = 1
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        MAX(u.LastAccessDate) AS LastActive,
        SUM(p.ViewCount) FILTER (WHERE p.OwnerUserId = u.Id) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    ua.LastActive,
    ua.TotalViews,
    COALESCE(up.TotalBounty, 0) AS TotalBounty,
    COALESCE(up.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN up.rn = 1 THEN 'Most Recent'
        ELSE 'Older Post'
    END AS PostStatus
FROM 
    RankedPosts up
JOIN 
    UserBadges ub ON up.OwnerUserId = ub.UserId
JOIN 
    UserActivity ua ON up.OwnerUserId = ua.UserId
WHERE 
    up.Score > (SELECT AVG(Score) FROM Posts) -- Only select posts with above average score
ORDER BY 
    up.Score DESC, 
    up.CreationDate DESC
LIMIT 100;

WITH 
-- Fetch close reasons
CloseReasons AS (
    SELECT DISTINCT 
        ph.PostId, 
        GROUP_CONCAT(DISTINCT crt.Name ORDER BY crt.Name) AS CloseReasonNames
    FROM 
        PostHistory ph 
    JOIN 
        CloseReasonTypes crt ON ph.Comment = crt.Id 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Close and Reopen
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    COALESCE(cr.CloseReasonNames, 'No close reasons') AS CloseReasons,
    COALESCE(com.CommentCount, 0) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    CloseReasons cr ON p.Id = cr.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) com ON p.Id = com.PostId
WHERE 
    p.ViewCount > 1000 -- Posts with significant views
    AND (p.ClosedDate IS NOT NULL OR cr.CloseReasonNames IS NOT NULL) -- Interested in closed or recently interacted posts
ORDER BY 
    p.ViewCount DESC
LIMIT 50;
