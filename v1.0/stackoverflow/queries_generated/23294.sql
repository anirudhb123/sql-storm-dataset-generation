WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY 
        p.Id
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName AS UserDisplayName,
    up.Title,
    up.CreationDate,
    up.ViewCount,
    up.Score,
    up.UserScoreRank,
    COALESCE(cr.CloseReasons, 'Not Closed') AS CloseStatus,
    ub.BadgeCount,
    ub.BadgeNames,
    (up.UpVoteCount - up.DownVoteCount) AS VoteBalance,
    CASE 
        WHEN up.UserScoreRank <= 3 THEN 'Top Performer'
        WHEN ub.BadgeCount > 5 THEN 'Pro User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    RankedPosts up
JOIN 
    Users u ON up.OwnerUserId = u.Id
LEFT JOIN 
    CloseReasons cr ON cr.PostId = up.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = u.Id
WHERE 
    up.UserScoreRank IS NOT NULL
    AND (up.CloseReasons IS NULL OR u.Reputation > 100) -- Filter based on reputation if closed
ORDER BY 
    up.Score DESC, up.ViewCount DESC
LIMIT 100;

