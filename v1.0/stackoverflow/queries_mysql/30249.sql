
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        @row_number := IF(@current_user = p.OwnerUserId, @row_number + 1, 1) AS PostRank,
        @current_user := p.OwnerUserId
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id, (SELECT @row_number := 0, @current_user := NULL) AS init
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(rp.BadgeCount, 0) AS BadgeCount,
        COALESCE(cl.ClosedDate, NULL) AS LastClosedDate,
        COALESCE(cl.CloseReason, 'Not Closed') AS LastCloseReason
    FROM 
        Posts p
    LEFT JOIN 
        UserBadges rp ON p.OwnerUserId = rp.UserId
    LEFT JOIN 
        ClosedQuestions cl ON p.Id = cl.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
)
SELECT 
    rp.Id,
    rp.Title,
    rp.ViewCount,
    rp.BadgeCount,
    rp.LastClosedDate,
    rp.LastCloseReason,
    CASE 
        WHEN rp.BadgeCount > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeStatus,
    CASE 
        WHEN rp.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RecentPosts rp
WHERE 
    rp.ViewCount > (SELECT AVG(ViewCount) FROM Posts)
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;
