
WITH UserScores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.UpVotes - u.DownVotes AS NetVotes,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        @row_number := IF(@current_owner = p.OwnerUserId, @row_number + 1, 1) AS rn,
        @current_owner := p.OwnerUserId
    FROM 
        Posts p, (SELECT @row_number := 0, @current_owner := NULL) r
    WHERE 
        p.CreationDate >= CURDATE() - INTERVAL 30 DAY
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
),
PostActions AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 12 THEN 'Deleted'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS ActionType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURDATE() - INTERVAL 90 DAY
),
AggregatedActions AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN ActionType = 'Closed' THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN ActionType = 'Deleted' THEN 1 END) AS DeletedCount,
        COUNT(CASE WHEN ActionType = 'Reopened' THEN 1 END) AS ReopenedCount
    FROM 
        PostActions
    GROUP BY 
        UserId
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.NetVotes,
    us.BadgeCount,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    COALESCE(aa.ClosedCount, 0) AS TotalClosed,
    COALESCE(aa.DeletedCount, 0) AS TotalDeleted,
    COALESCE(aa.ReopenedCount, 0) AS TotalReopened,
    CASE 
        WHEN us.Reputation >= 1000 AND us.BadgeCount > 5 THEN 'Veteran'
        WHEN us.Reputation < 1000 AND us.BadgeCount < 3 THEN 'Newbie'
        ELSE 'Intermediate'
    END AS UserType
FROM 
    UserScores us
JOIN 
    RecentPosts rp ON us.UserId = rp.OwnerUserId
LEFT JOIN 
    AggregatedActions aa ON us.UserId = aa.UserId
WHERE 
    us.Reputation > 0
ORDER BY 
    us.Reputation DESC, rp.ViewCount DESC
LIMIT 50;
