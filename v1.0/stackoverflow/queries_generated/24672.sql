WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBountyAmount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- BountyStart, BountyClose
    WHERE 
        p.CreationDate > NOW() - INTERVAL '2 years'
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass 
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS TotalCloseReopen,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS TotalDeleteUndelete,
        COUNT(*) AS TotalHistoryEntries
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    up.PostId,
    up.Title,
    up.CreationDate,
    up.Score,
    up.CommentCount,
    up.TotalBountyAmount,
    ub.BadgeCount,
    CASE 
        WHEN ub.HighestBadgeClass = 1 THEN 'Gold'
        WHEN ub.HighestBadgeClass = 2 THEN 'Silver'
        WHEN ub.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeLevel,
    pht.TotalCloseReopen,
    pht.TotalDeleteUndelete,
    CASE 
        WHEN up.CommentCount = 0 THEN 'No Comments'
        ELSE CONCAT(up.CommentCount, ' Comments')
    END AS CommentStatus,
    CASE 
        WHEN up.Score > 0 THEN 'Positive Score'
        WHEN up.Score < 0 THEN 'Negative Score'
        ELSE 'Neutral Score'
    END AS ScoreStatus
FROM 
    Users u
JOIN 
    RankedPosts up ON u.Id = up.OwnerUserId
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PostHistorySummary pht ON up.PostId = pht.PostId
WHERE 
    up.rn = 1 
    AND (up.TotalBountyAmount > 0 OR up.CommentCount > 2)
ORDER BY 
    u.Reputation DESC,
    up.Score DESC
LIMIT 100;
