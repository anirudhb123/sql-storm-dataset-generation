WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PostClosureReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CASE WHEN ph.PostHistoryTypeId = 10 THEN cr.Name END, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
), FinalPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UserPostRank,
        ub.BadgeCount,
        ub.HighestBadgeClass,
        pcr.CloseReasons
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        PostClosureReasons pcr ON rp.PostId = pcr.PostId
    WHERE 
        rp.UserPostRank <= 5
)

SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.BadgeCount,
    fp.HighestBadgeClass,
    COALESCE(fp.CloseReasons, 'No Close Reasons') AS CloseReasons,
    CASE 
        WHEN fp.Score >= 10 THEN 'Highly Engaged'
        WHEN fp.Score BETWEEN 1 AND 9 THEN 'Moderately Engaged'
        ELSE 'Low Engagement'
    END AS EngagementLevel,
    CONCAT(fp.Title, ' (', fp.CreationDate::date, ')') AS DisplayTitle
FROM 
    FinalPosts fp
WHERE 
    fp.BadgeCount > 0 OR fp.CloseReasons IS NOT NULL
ORDER BY 
    fp.Score DESC, fp.CreationDate ASC
LIMIT 100;
