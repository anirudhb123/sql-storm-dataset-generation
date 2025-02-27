
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS RowNum,
        @prev_owner := p.OwnerUserId
    FROM Posts p
    JOIN (SELECT @row_num := 0, @prev_owner := NULL) r
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY p.OwnerUserId, p.Score DESC
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment,
        p.Title,
        @history_row_num := IF(@prev_post = ph.PostId, @history_row_num + 1, 1) AS HistoryRowNum,
        @prev_post := ph.PostId
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    JOIN (SELECT @history_row_num := 0, @prev_post := NULL) r
    WHERE ph.PostHistoryTypeId IN (10, 11) 
    ORDER BY ph.PostId, ph.CreationDate DESC
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name ORDER BY b.Name SEPARATOR ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    CASE 
        WHEN ub.BadgeCount > 0 THEN ub.BadgeCount 
        ELSE 0 
    END AS TotalBadges,
    ub.BadgeNames,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.CreationDate AS PopularPostDate,
    pp.Score AS PopularPostScore,
    ch.PostId AS ClosedPostId,
    ch.CreationDate AS ClosedPostDate,
    ch.UserDisplayName AS ClosedBy,
    ch.Comment AS CloseReason,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pp.PostId) AS CommentCount
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN PopularPosts pp ON u.Id = pp.OwnerUserId AND pp.RowNum = 1
LEFT JOIN ClosedPostHistory ch ON pp.PostId = ch.PostId AND ch.HistoryRowNum = 1
WHERE u.Reputation > 2000
ORDER BY u.Reputation DESC, pp.Score DESC;
