WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE (
            (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 
            0
        ) AS UpVotesCount
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
), RecentPosts AS (
    SELECT 
        rp.*, 
        CASE 
            WHEN rp.ViewCount > 100 THEN 'High View'
            WHEN rp.ViewCount BETWEEN 50 AND 100 THEN 'Medium View'
            ELSE 'Low View' 
        END AS ViewCategory
    FROM RankedPosts rp
    WHERE rp.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
), UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount, 
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), PostInteraction AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCategory,
        ub.BadgeCount,
        ub.BadgeNames,
        COALESCE (
            (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId), 
            0
        ) AS CommentCount,
        CASE 
            WHEN rp.Score > 0 THEN 'Popular'
            WHEN rp.Score < 0 THEN 'Unfavorable'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM RecentPosts rp
    LEFT JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
), ClosingPostReasons AS (
    SELECT 
        ph.PostId, 
        ph.PostHistoryTypeId, 
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11) -- Closed and reopened
    GROUP BY ph.PostId, ph.PostHistoryTypeId
), FinalResults AS (
    SELECT 
        pi.*, 
        COALESCE (
            (SELECT STRING_AGG(cr.Name, ', ') 
             FROM ClosingPostReasons cpr
             JOIN CloseReasonTypes cr ON cpr.PostHistoryTypeId = cr.Id
             WHERE cpr.PostId = pi.PostId),
            'No closure'
        ) AS CloseReason,
        CASE 
            WHEN pi.BadgeCount > 5 THEN 'Super User'
            ELSE 'Regular User'
        END AS UserCategory
    FROM PostInteraction pi
)
SELECT 
    PostId,
    Title,
    ViewCategory,
    BadgeCount,
    BadgeNames,
    CommentCount,
    ScoreCategory,
    CloseReason,
    UserCategory
FROM FinalResults
WHERE UserCategory = 'Super User' 
  AND ViewCategory = 'High View'
ORDER BY CommentCount DESC, ScoreCategory ASC;
