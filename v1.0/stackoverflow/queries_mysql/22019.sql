
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Ranking,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgesCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(CASE WHEN ph.Comment IS NOT NULL THEN CONCAT('Closed for: ', cr.Name) END SEPARATOR ', ') AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON CAST(ph.Comment AS UNSIGNED) = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    up.PostId,
    up.Title,
    up.CreationDate,
    up.ViewCount,
    up.Score,
    ub.BadgesCount,
    ub.BadgeNames,
    cr.CloseReason,
    CASE 
        WHEN cr.CloseReason IS NULL THEN 'Open'
        ELSE 'Closed'
    END AS PostStatus,
    (up.Upvotes - up.Downvotes) AS NetVotes
FROM 
    RankedPosts up
LEFT JOIN 
    UserBadges ub ON up.PostId = ub.UserId
LEFT JOIN 
    CloseReasons cr ON up.PostId = cr.PostId
WHERE 
    up.Ranking <= 10
ORDER BY 
    up.Score DESC
LIMIT 50;
