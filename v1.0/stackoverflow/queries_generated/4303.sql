WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(cr.Name) AS CloseReasonNames
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(cr.CloseReasonNames, 'No close reasons') AS CloseReasons,
    ub.BadgeNames,
    CASE 
        WHEN rp.UserRank = 1 THEN 'Top Post'
        ELSE CONCAT('Rank ', rp.UserRank, ' out of ', rp.TotalPosts)
    END AS RankingStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    CloseReasons cr ON rp.PostId = cr.PostId
LEFT JOIN 
    UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE 
    rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;
